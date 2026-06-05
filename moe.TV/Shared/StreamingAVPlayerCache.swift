import AVFoundation
import Combine
import CryptoKit
import Foundation

struct CachedRange: Codable, Equatable {
	var start: Int64
	var end: Int64

	var length: Int64 {
		max(0, end - start + 1)
	}

	func contains(_ range: CachedRange) -> Bool {
		start <= range.start && end >= range.end
	}

	func intersectsOrTouches(_ range: CachedRange) -> Bool {
		range.start <= end + 1 && range.end + 1 >= start
	}
}

struct StreamingCacheState: Equatable {
	var contentLength: Int64 = 0
	var cachedRanges: [CachedRange] = []
	var lastRequestedOffset: Int64 = 0
	var lastRequestedEndOffset: Int64 = 0
	var isPrepared = false
	var isPrefetching = false
}

struct StreamingCacheConfiguration {
	var prefetchLength: Int64 = 64 * 1024 * 1024
	var requestChunkSize: Int64 = 1024 * 1024
	var maxRetryCount = 2
	var retryBaseDelay: TimeInterval = 0.4
	var maxCacheBytes: Int64 = 3 * 1024 * 1024 * 1024
	var maxCacheAge: TimeInterval = 7 * 24 * 60 * 60
	var removesCacheOnStop = false
}

enum StreamingCacheError: Error {
	case invalidResponse
	case rangeNotSupported
	case missingContentLength
	case invalidRange
	case unexpectedStatusCode(Int)
	case unexpectedContentLength(expected: Int64, actual: Int64)
	case unexpectedContentRange(String)
	case cacheFileInvalid
}

private struct StreamingCacheMetadata: Codable {
	var originalURL: String
	var contentLength: Int64
	var contentType: String
	var cachedRanges: [CachedRange]
	var lastAccessDate: Date
}

@MainActor
final class StreamingCacheManager: ObservableObject {
	@Published private(set) var state = StreamingCacheState()

	private let originalURL: URL
	private let cacheFileURL: URL
	private let metadataFileURL: URL
	private let cacheDirectory: URL
	private let configuration: StreamingCacheConfiguration
	private let session: URLSession
	private let ioQueue = DispatchQueue(label: "moe.tv.streaming-cache.io")

	private var contentType = AVFileType.mp4.rawValue
	private var activePrefetchTask: Task<Void, Never>?
	private var activePrefetchRange: CachedRange?
	private var isStopped = false

	init(
		originalURL: URL,
		cacheDirectory: URL? = nil,
		configuration: StreamingCacheConfiguration = StreamingCacheConfiguration()
	) throws {
		self.originalURL = originalURL
		self.configuration = configuration

		let baseDirectory: URL
		if let cacheDirectory {
			baseDirectory = cacheDirectory
		} else {
			baseDirectory = try FileManager.default
				.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
				.appendingPathComponent("streaming-cache", isDirectory: true)
		}

		self.cacheDirectory = baseDirectory
		try FileManager.default.createDirectory(at: baseDirectory, withIntermediateDirectories: true)

		let key = Self.cacheKey(for: originalURL.absoluteString)
		self.cacheFileURL = baseDirectory.appendingPathComponent("\(key).mp4")
		self.metadataFileURL = baseDirectory.appendingPathComponent("\(key).json")

		let config = URLSessionConfiguration.default
		config.requestCachePolicy = .reloadIgnoringLocalCacheData
		config.urlCache = nil
		self.session = URLSession(configuration: config)

		loadMetadataFromDisk()
	}

	var currentContentType: String {
		contentType
	}

	func prepare() async throws {
		guard !isStopped else { throw CancellationError() }
		guard !state.isPrepared else {
			touchMetadata()
			return
		}

		var request = URLRequest(url: originalURL)
		request.setValue("bytes=0-1", forHTTPHeaderField: "Range")
		request.setValue("identity", forHTTPHeaderField: "Accept-Encoding")

		let (_, response) = try await session.data(for: request)
		guard let http = response as? HTTPURLResponse else {
			throw StreamingCacheError.invalidResponse
		}

		guard http.statusCode == 206 else {
			throw StreamingCacheError.rangeNotSupported
		}

		guard let contentRange = http.value(forHTTPHeaderField: "Content-Range"),
			  let length = Self.parseContentLength(from: contentRange) else {
			throw StreamingCacheError.missingContentLength
		}

		if let mimeType = http.mimeType, !mimeType.isEmpty {
			contentType = mimeType
		}

		state.contentLength = length
		state.isPrepared = true
		try createCacheFileIfNeeded(length: length)
		saveMetadataToDisk()
	}

	func data(for requestedRange: CachedRange) async throws -> Data {
		guard !isStopped else { throw CancellationError() }
		try validate(range: requestedRange)
		try await prepare()

		let cappedRange = CachedRange(
			start: requestedRange.start,
			end: min(requestedRange.end, state.contentLength - 1)
		)

		state.lastRequestedOffset = cappedRange.start
		state.lastRequestedEndOffset = cappedRange.end

		let missingRanges = missingRanges(in: cappedRange)
		for range in missingRanges {
			try Task.checkCancellation()
			let data = try await downloadWithRetry(range: range)
			try write(data: data, at: range.start)
			addCachedRange(range)
		}

		touchMetadata()
		return try read(range: cappedRange)
	}

	func prefetch(from start: Int64, length: Int64? = nil) {
		guard !isStopped else { return }
		guard state.contentLength > 0 else { return }

		let prefetchLength = length ?? configuration.prefetchLength
		let safeStart = max(0, min(start, state.contentLength - 1))
		let safeEnd = max(safeStart, min(state.contentLength - 1, safeStart + prefetchLength - 1))
		let requestedPrefetchRange = CachedRange(start: safeStart, end: safeEnd)

		if let activePrefetchRange,
		   activePrefetchRange.start <= safeStart,
		   activePrefetchRange.end >= min(safeEnd, safeStart + configuration.requestChunkSize - 1) {
			return
		}

		activePrefetchTask?.cancel()
		activePrefetchRange = requestedPrefetchRange

		activePrefetchTask = Task { [weak self] in
			guard let self else { return }

			await MainActor.run {
				self.state.isPrefetching = true
			}

			defer {
				Task { @MainActor in
					if self.activePrefetchRange == requestedPrefetchRange {
						self.activePrefetchRange = nil
					}
					self.state.isPrefetching = self.activePrefetchRange != nil
				}
			}

			do {
				try await self.prepare()

				var offset = await MainActor.run {
					self.firstUncachedOffset(atOrAfter: safeStart)
				}

				while offset <= safeEnd {
					try Task.checkCancellation()

					let chunkEnd = min(safeEnd, offset + self.configuration.requestChunkSize - 1)
					let range = CachedRange(start: offset, end: chunkEnd)
					_ = try await self.data(for: range)

					offset = await MainActor.run {
						self.firstUncachedOffset(atOrAfter: chunkEnd + 1)
					}
				}
			} catch is CancellationError {
				return
			} catch {
				let nsError = error as NSError
				if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
					return
				}
				print("Streaming prefetch failed: \(error)")
			}
		}
	}

	func prefetchFromLastRequestedOffset(length: Int64? = nil) {
		prefetchAfterCachedRange(containing: state.lastRequestedEndOffset, length: length)
	}

	func prefetchAfterCachedRange(containing offset: Int64, length: Int64? = nil) {
		guard state.contentLength > 0 else { return }
		let start = firstUncachedOffset(atOrAfter: offset)
		prefetch(from: start, length: length)
	}

	func cancelPrefetch() {
		activePrefetchTask?.cancel()
		activePrefetchTask = nil
		activePrefetchRange = nil
		state.isPrefetching = false
	}

	func stop(deleteCache: Bool? = nil) {
		isStopped = true
		activePrefetchTask?.cancel()
		activePrefetchTask = nil
		activePrefetchRange = nil
		session.invalidateAndCancel()

		if deleteCache ?? configuration.removesCacheOnStop {
			deleteCacheFiles()
		} else {
			saveMetadataToDisk()
		}
	}

	func deleteCacheFiles() {
		try? FileManager.default.removeItem(at: cacheFileURL)
		try? FileManager.default.removeItem(at: metadataFileURL)
		state.cachedRanges = []
		state.isPrepared = false
		state.contentLength = 0
	}

	static func cleanupCacheDirectory(
		cacheDirectory: URL? = nil,
		maxCacheBytes: Int64 = StreamingCacheConfiguration().maxCacheBytes,
		maxCacheAge: TimeInterval = StreamingCacheConfiguration().maxCacheAge
	) {
		let fileManager = FileManager.default

		guard let directory = try? cacheDirectory ?? fileManager
			.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
			.appendingPathComponent("streaming-cache", isDirectory: true),
			  let files = try? fileManager.contentsOfDirectory(
				at: directory,
				includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
				options: [.skipsHiddenFiles]
			  ) else {
			return
		}

		let now = Date()
		let metadataFiles = files.filter { $0.pathExtension == "json" }

		for metadataURL in metadataFiles {
			guard let data = try? Data(contentsOf: metadataURL),
				  let metadata = try? JSONDecoder().decode(StreamingCacheMetadata.self, from: data) else {
				continue
			}

			if now.timeIntervalSince(metadata.lastAccessDate) > maxCacheAge {
				let videoURL = metadataURL.deletingPathExtension().appendingPathExtension("mp4")
				try? fileManager.removeItem(at: videoURL)
				try? fileManager.removeItem(at: metadataURL)
			}
		}

		guard let refreshedFiles = try? fileManager.contentsOfDirectory(
			at: directory,
			includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
			options: [.skipsHiddenFiles]
		) else {
			return
		}

		let videos = refreshedFiles
			.filter { $0.pathExtension == "mp4" }
			.map { url -> (url: URL, size: Int64, modified: Date) in
				let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
				return (
					url,
					Int64(values?.fileSize ?? 0),
					values?.contentModificationDate ?? .distantPast
				)
			}
			.sorted { $0.modified < $1.modified }

		var totalBytes = videos.reduce(Int64(0)) { $0 + $1.size }
		for video in videos where totalBytes > maxCacheBytes {
			let metadataURL = video.url.deletingPathExtension().appendingPathExtension("json")
			try? fileManager.removeItem(at: video.url)
			try? fileManager.removeItem(at: metadataURL)
			totalBytes -= video.size
		}
	}

	private func downloadWithRetry(range: CachedRange) async throws -> Data {
		var attempt = 0

		while true {
			do {
				return try await downloadOnce(range: range)
			} catch {
				guard shouldRetry(error), attempt < configuration.maxRetryCount else {
					throw error
				}

				attempt += 1
				let delay = configuration.retryBaseDelay * pow(2, Double(attempt - 1))
				try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
			}
		}
	}

	private func downloadOnce(range: CachedRange) async throws -> Data {
		var request = URLRequest(url: originalURL)
		request.setValue("bytes=\(range.start)-\(range.end)", forHTTPHeaderField: "Range")
		request.setValue("identity", forHTTPHeaderField: "Accept-Encoding")

		let (data, response) = try await session.data(for: request)

		guard let http = response as? HTTPURLResponse else {
			throw StreamingCacheError.invalidResponse
		}

		guard http.statusCode == 206 else {
			if http.statusCode == 200 {
				throw StreamingCacheError.rangeNotSupported
			}
			throw StreamingCacheError.unexpectedStatusCode(http.statusCode)
		}

		if let contentRange = http.value(forHTTPHeaderField: "Content-Range") {
			try validateContentRange(contentRange, requestedRange: range)
		}

		let actualLength = Int64(data.count)
		guard actualLength == range.length else {
			throw StreamingCacheError.unexpectedContentLength(expected: range.length, actual: actualLength)
		}

		return data
	}

	private func shouldRetry(_ error: Error) -> Bool {
		if error is CancellationError {
			return false
		}

		let nsError = error as NSError
		if nsError.domain == NSURLErrorDomain {
			switch nsError.code {
			case NSURLErrorCancelled:
				return false
			case NSURLErrorTimedOut,
				 NSURLErrorCannotFindHost,
				 NSURLErrorCannotConnectToHost,
				 NSURLErrorNetworkConnectionLost,
				 NSURLErrorDNSLookupFailed,
				 NSURLErrorNotConnectedToInternet,
				 NSURLErrorSecureConnectionFailed:
				return true
			default:
				return false
			}
		}

		if case StreamingCacheError.unexpectedStatusCode(let statusCode) = error {
			return statusCode == 408 || statusCode == 425 || statusCode == 429 || (500...599).contains(statusCode)
		}

		return false
	}

	private func validateContentRange(_ contentRange: String, requestedRange: CachedRange) throws {
		guard let parsedRange = Self.parseContentRange(contentRange) else {
			throw StreamingCacheError.unexpectedContentRange(contentRange)
		}

		guard parsedRange.start == requestedRange.start,
			  parsedRange.end == requestedRange.end else {
			throw StreamingCacheError.unexpectedContentRange(contentRange)
		}
	}

	private func firstUncachedOffset(atOrAfter offset: Int64) -> Int64 {
		guard state.contentLength > 0 else { return offset }

		var cursor = max(0, min(offset, state.contentLength - 1))
		for cached in state.cachedRanges.sorted(by: { $0.start < $1.start }) {
			if cached.end < cursor {
				continue
			}
			if cached.start > cursor {
				break
			}
			cursor = min(state.contentLength, cached.end + 1)
			if cursor >= state.contentLength {
				break
			}
		}

		return cursor
	}

	private func missingRanges(in requestedRange: CachedRange) -> [CachedRange] {
		var missing: [CachedRange] = []
		var cursor = requestedRange.start

		for cached in state.cachedRanges.sorted(by: { $0.start < $1.start }) {
			if cached.end < cursor {
				continue
			}
			if cached.start > requestedRange.end {
				break
			}
			if cached.start > cursor {
				missing.append(CachedRange(start: cursor, end: min(cached.start - 1, requestedRange.end)))
			}
			cursor = max(cursor, cached.end + 1)
			if cursor > requestedRange.end {
				break
			}
		}

		if cursor <= requestedRange.end {
			missing.append(CachedRange(start: cursor, end: requestedRange.end))
		}

		return missing
	}

	private func read(range: CachedRange) throws -> Data {
		try ioQueue.sync {
			let handle = try FileHandle(forReadingFrom: cacheFileURL)
			defer { try? handle.close() }
			try handle.seek(toOffset: UInt64(range.start))
			return handle.readData(ofLength: Int(range.length))
		}
	}

	private func write(data: Data, at offset: Int64) throws {
		try ioQueue.sync {
			let handle = try FileHandle(forWritingTo: cacheFileURL)
			defer { try? handle.close() }
			try handle.seek(toOffset: UInt64(offset))
			try handle.write(contentsOf: data)
		}
	}

	private func addCachedRange(_ range: CachedRange) {
		var ranges = state.cachedRanges
		ranges.append(range)
		ranges.sort { $0.start < $1.start }

		var merged: [CachedRange] = []
		for range in ranges {
			guard var last = merged.popLast() else {
				merged.append(range)
				continue
			}

			if last.intersectsOrTouches(range) {
				last.end = max(last.end, range.end)
				merged.append(last)
			} else {
				merged.append(last)
				merged.append(range)
			}
		}

		state.cachedRanges = merged
		saveMetadataToDisk()
	}

	private func validate(range: CachedRange) throws {
		guard range.start >= 0, range.end >= range.start else {
			throw StreamingCacheError.invalidRange
		}
	}

	private func createCacheFileIfNeeded(length: Int64) throws {
		if !FileManager.default.fileExists(atPath: cacheFileURL.path) {
			FileManager.default.createFile(atPath: cacheFileURL.path, contents: nil)
		}

		let handle = try FileHandle(forWritingTo: cacheFileURL)
		defer { try? handle.close() }
		try handle.truncate(atOffset: UInt64(length))
	}

	private func loadMetadataFromDisk() {
		guard let data = try? Data(contentsOf: metadataFileURL),
			  let metadata = try? JSONDecoder().decode(StreamingCacheMetadata.self, from: data),
			  metadata.originalURL == originalURL.absoluteString else {
			return
		}

		guard metadata.contentLength > 0,
			  FileManager.default.fileExists(atPath: cacheFileURL.path),
			  fileSize(at: cacheFileURL) == metadata.contentLength else {
			try? FileManager.default.removeItem(at: cacheFileURL)
			try? FileManager.default.removeItem(at: metadataFileURL)
			return
		}

		contentType = metadata.contentType
		state.contentLength = metadata.contentLength
		state.cachedRanges = metadata.cachedRanges
		state.isPrepared = metadata.contentLength > 0
	}

	private func saveMetadataToDisk() {
		let metadata = StreamingCacheMetadata(
			originalURL: originalURL.absoluteString,
			contentLength: state.contentLength,
			contentType: contentType,
			cachedRanges: state.cachedRanges,
			lastAccessDate: Date()
		)

		guard let data = try? JSONEncoder().encode(metadata) else {
			return
		}

		try? data.write(to: metadataFileURL, options: .atomic)
	}

	private func touchMetadata() {
		saveMetadataToDisk()
	}

	private static func parseContentLength(from contentRange: String) -> Int64? {
		guard let total = contentRange.split(separator: "/").last else {
			return nil
		}
		return Int64(total)
	}

	private static func parseContentRange(_ contentRange: String) -> (start: Int64, end: Int64, total: Int64)? {
		let parts = contentRange.split(separator: " ")
		guard parts.count == 2,
			  parts[0].lowercased() == "bytes" else {
			return nil
		}

		let rangeAndTotal = parts[1].split(separator: "/")
		guard rangeAndTotal.count == 2,
			  let total = Int64(rangeAndTotal[1]) else {
			return nil
		}

		let bounds = rangeAndTotal[0].split(separator: "-")
		guard bounds.count == 2,
			  let start = Int64(bounds[0]),
			  let end = Int64(bounds[1]) else {
			return nil
		}

		return (start, end, total)
	}

	private func fileSize(at url: URL) -> Int64 {
		guard let values = try? url.resourceValues(forKeys: [.fileSizeKey]) else {
			return -1
		}
		return Int64(values.fileSize ?? -1)
	}

	private static func cacheKey(for string: String) -> String {
		let digest = SHA256.hash(data: Data(string.utf8))
		return digest.map { String(format: "%02x", $0) }.joined()
	}
}

final class StreamingResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
	let cacheManager: StreamingCacheManager

	private let taskLock = NSLock()
	private var tasks: [ObjectIdentifier: Task<Void, Never>] = [:]
	private let responseChunkSize: Int64

	init(cacheManager: StreamingCacheManager, responseChunkSize: Int64 = 1024 * 1024) {
		self.cacheManager = cacheManager
		self.responseChunkSize = responseChunkSize
		super.init()
	}

	func resourceLoader(
		_ resourceLoader: AVAssetResourceLoader,
		shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
	) -> Bool {
		let task = Task { [weak self, weak loadingRequest] in
			guard let self, let loadingRequest else { return }

			do {
				await MainActor.run {
					self.cacheManager.cancelPrefetch()
				}
				try await self.fill(loadingRequest)
				loadingRequest.finishLoading()
			} catch is CancellationError {
				loadingRequest.finishLoading(with: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled))
			} catch {
				loadingRequest.finishLoading(with: error)
			}

			self.removeTask(for: loadingRequest)
		}

		setTask(task, for: loadingRequest)
		return true
	}

	func resourceLoader(
		_ resourceLoader: AVAssetResourceLoader,
		didCancel loadingRequest: AVAssetResourceLoadingRequest
	) {
		task(for: loadingRequest)?.cancel()
		removeTask(for: loadingRequest)
	}

	func cancelAllLoadingRequests() {
		taskLock.lock()
		let currentTasks = Array(tasks.values)
		tasks.removeAll()
		taskLock.unlock()

		currentTasks.forEach { $0.cancel() }
	}

	private func fill(_ loadingRequest: AVAssetResourceLoadingRequest) async throws {
		try await cacheManager.prepare()

		if let contentInformationRequest = loadingRequest.contentInformationRequest {
			let contentLength = await MainActor.run { cacheManager.state.contentLength }
			contentInformationRequest.contentType = AVFileType.mp4.rawValue
			contentInformationRequest.contentLength = contentLength
			contentInformationRequest.isByteRangeAccessSupported = true
		}

		guard let dataRequest = loadingRequest.dataRequest else {
			return
		}

		let requestedOffset = dataRequest.requestedOffset
		let requestedLength = Int64(dataRequest.requestedLength)
		guard requestedLength > 0 else { return }

		let contentLength = await MainActor.run { cacheManager.state.contentLength }
		let requestedEnd = min(contentLength - 1, requestedOffset + requestedLength - 1)
		var offset = dataRequest.currentOffset != 0 ? dataRequest.currentOffset : requestedOffset

		while offset <= requestedEnd {
			try Task.checkCancellation()

			let chunkEnd = min(requestedEnd, offset + responseChunkSize - 1)
			let range = CachedRange(start: offset, end: chunkEnd)
			let data = try await cacheManager.data(for: range)
			dataRequest.respond(with: data)

			offset = chunkEnd + 1
		}

		await MainActor.run {
			cacheManager.prefetchAfterCachedRange(containing: requestedEnd)
		}
	}

	private func setTask(_ task: Task<Void, Never>, for loadingRequest: AVAssetResourceLoadingRequest) {
		taskLock.lock()
		tasks[ObjectIdentifier(loadingRequest)] = task
		taskLock.unlock()
	}

	private func task(for loadingRequest: AVAssetResourceLoadingRequest) -> Task<Void, Never>? {
		taskLock.lock()
		let task = tasks[ObjectIdentifier(loadingRequest)]
		taskLock.unlock()
		return task
	}

	private func removeTask(for loadingRequest: AVAssetResourceLoadingRequest) {
		taskLock.lock()
		tasks[ObjectIdentifier(loadingRequest)] = nil
		taskLock.unlock()
	}
}

final class StreamingPlayerItemFactory {
	private let configuration: StreamingCacheConfiguration
	private let loaderQueue = DispatchQueue(label: "moe.tv.streaming-resource-loader")

	private(set) var cacheManager: StreamingCacheManager?
	private var resourceLoaderDelegate: StreamingResourceLoaderDelegate?

	init(configuration: StreamingCacheConfiguration = StreamingCacheConfiguration()) {
		self.configuration = configuration
	}

	@MainActor
	func makePlayerItem(for url: URL) throws -> AVPlayerItem {
		stop()

		StreamingCacheManager.cleanupCacheDirectory(
			maxCacheBytes: configuration.maxCacheBytes,
			maxCacheAge: configuration.maxCacheAge
		)

		let cacheManager = try StreamingCacheManager(originalURL: url, configuration: configuration)
		let delegate = StreamingResourceLoaderDelegate(
			cacheManager: cacheManager,
			responseChunkSize: configuration.requestChunkSize
		)

		let assetURL = try Self.resourceLoaderURL(for: url)
		let asset = AVURLAsset(url: assetURL)
		asset.resourceLoader.setDelegate(delegate, queue: loaderQueue)

		self.cacheManager = cacheManager
		self.resourceLoaderDelegate = delegate

		return AVPlayerItem(asset: asset)
	}

	@MainActor
	func stop(deleteCache: Bool? = nil) {
		resourceLoaderDelegate?.cancelAllLoadingRequests()
		resourceLoaderDelegate = nil
		cacheManager?.stop(deleteCache: deleteCache)
		cacheManager = nil
	}

	static func resourceLoaderURL(for originalURL: URL) throws -> URL {
		guard var components = URLComponents(url: originalURL, resolvingAgainstBaseURL: false),
			  let scheme = components.scheme else {
			throw StreamingCacheError.invalidResponse
		}

		components.scheme = "moetv-cache-\(scheme)"

		guard let url = components.url else {
			throw StreamingCacheError.invalidResponse
		}

		return url
	}
}
