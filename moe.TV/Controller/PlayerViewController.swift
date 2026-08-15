//
//  PlayerViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/04.
//
import AVFoundation
import AVKit
import Combine
import Foundation
import MediaPlayer
#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct PlaybackProgressSnapshot {
	let position: Double
	let percentage: Double
	let isFinished: Bool
}

class PlayerViewController: ObservableObject {
	@Published var avPlayer: AVPlayer?
	@Published var streamingCacheManager: StreamingCacheManager?

	@Published var currentTime: Double = 0
	@Published var duration: Double = 0
	@Published var isPlaying = false
	@Published var isSeeking = false
	@Published var playbackRate: Double = 1.0
	@Published var loadedTimeRanges: [ClosedRange<Double>] = []
	@Published var volume: Float = 1.0

	private let streamingFactory = StreamingPlayerItemFactory()
	private var timeObserverToken: Any?
	private var stallRecoveryTask: Task<Void, Never>?
	private var shouldResumeAfterStall = false
	private var lastStreamingPrefetchMaintenanceDate: Date?
	private var cancellables = Set<AnyCancellable>()
	private var itemCancellables = Set<AnyCancellable>()
	private var isRecoveringFromStall = false
	private var currentStreamingURL: URL?
	private var lastPlaybackLogKey: String?
	private var lastPlaybackLogPosition: Double = -.infinity
	private var lastPlaybackLogDate = Date.distantPast

	let offlinePBM = OfflinePlaybackManager()
	var settingsHandler = SettingsHandler()

	deinit {
		Task { @MainActor [weak self] in
			self?.removeTimeObserver()
		}
	}

	@MainActor
	func loadFromUrl(url: URL, useStreamingCache: Bool = false) {
		print("url:\(redactedVideoCDNURLDescription(url))")

		resetPlayerState()

		if useStreamingCache {
			do {
				let item = try streamingFactory.makePlayerItem(for: url)
				streamingCacheManager = streamingFactory.cacheManager
				currentStreamingURL = url
				avPlayer = AVPlayer(playerItem: item)
			} catch {
				print("Streaming cache player failed, fallback to AVPlayer(url:): \(error)")
				streamingCacheManager = nil
				currentStreamingURL = nil
				avPlayer = AVPlayer(url: url)
			}
		} else {
			streamingCacheManager = nil
			currentStreamingURL = nil
			avPlayer = AVPlayer(url: url)
		}

		configureCurrentPlayer()
	}

	@MainActor
	func stop(deleteStreamingCache: Bool = false) {
		avPlayer?.pause()
		removeTimeObserver()
		streamingFactory.stop(deleteCache: deleteStreamingCache)
		streamingCacheManager = nil
		avPlayer = nil
		currentTime = 0
		duration = 0
		isPlaying = false
		isSeeking = false
		playbackRate = settingsHandler.getPlaybackRate()
		loadedTimeRanges = []
		volume = 1.0
		stallRecoveryTask?.cancel()
		stallRecoveryTask = nil
		shouldResumeAfterStall = false
		lastStreamingPrefetchMaintenanceDate = nil
		cancellables.removeAll()
		itemCancellables.removeAll()
		isRecoveringFromStall = false
		currentStreamingURL = nil
	}

	@MainActor
	func play() {
		shouldResumeAfterStall = true
		applyPlaybackRate()
		isPlaying = true
		prefetchStreamingForwardBuffer()
	}

	@MainActor
	func pause() {
		shouldResumeAfterStall = false
		stallRecoveryTask?.cancel()
		stallRecoveryTask = nil
		avPlayer?.pause()
		isPlaying = false
		prefetchStreamingForwardBufferForPausedPlayback()
	}

	@MainActor
	func togglePlayPause() {
		if avPlayer?.timeControlStatus == .playing {
			pause()
		} else {
			play()
		}
	}

	@MainActor
	func setPlaybackRate(_ rate: Double, persist: Bool = true) {
		let safeRate = max(0.25, min(rate, 3.0))
		playbackRate = safeRate
		avPlayer?.defaultRate = Float(safeRate)

		if avPlayer?.timeControlStatus == .playing {
			applyPlaybackRate()
		}

		if persist {
			settingsHandler.setPlaybackRate(rate: safeRate)
		}
	}

	@MainActor
	func seek(to seconds: Double, autoPlay: Bool = false) {
		guard let player = avPlayer else { return }

		let safeDuration = duration > 0 ? duration : CMTimeGetSeconds(player.currentItem?.duration ?? .zero)
		let targetSeconds = max(0, min(seconds, safeDuration.isFinite ? safeDuration : seconds))
		let target = CMTime(seconds: targetSeconds, preferredTimescale: Int32(NSEC_PER_SEC))

		isSeeking = true
		player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
			Task { @MainActor in
				guard let self else { return }
				self.currentTime = targetSeconds
				self.isSeeking = false

		if autoPlay, finished {
					self.play()
				}

				if self.isPlaying || autoPlay {
					self.prefetchStreamingForwardBuffer()
				} else {
					self.prefetchStreamingForwardBufferForPausedPlayback()
				}
			}
		}
	}

	@MainActor
	func seek(by delta: Double, autoPlay: Bool = false) {
		seek(to: currentTime + delta, autoPlay: autoPlay)
	}

	#if !os(tvOS)
	@MainActor
	func adjustVolume(by delta: Float) {
		guard let player = avPlayer else { return }
		setVolume(player.volume + delta)
	}

	@MainActor
	func setVolume(_ value: Float) {
		avPlayer?.volume = min(1, max(0, value))
	}
	#endif

	#if !os(tvOS)
	@MainActor
	func copyCurrentFrameToPasteboard(completion: ((Bool) -> Void)? = nil) {
		guard let currentItem = avPlayer?.currentItem else {
			completion?(false)
			return
		}

		let asset = currentItem.asset
		let time = currentItem.currentTime()

		Task.detached(priority: .userInitiated) {
			let generator = AVAssetImageGenerator(asset: asset)
			generator.appliesPreferredTrackTransform = true
			generator.requestedTimeToleranceBefore = .zero
			generator.requestedTimeToleranceAfter = .zero

			await withCheckedContinuation { continuation in
				generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, result, error in
					if let error {
						print("Failed to copy current video frame: \(error)")
					}

					guard result == .succeeded, let image else {
						Task { @MainActor in
							completion?(false)
							continuation.resume()
						}
						return
					}

					Task { @MainActor in
						let didCopy: Bool
						#if os(iOS) || os(visionOS)
						UIPasteboard.general.image = UIImage(cgImage: image)
						didCopy = true
						#elseif os(macOS)
						let pasteboard = NSPasteboard.general
						pasteboard.clearContents()
						didCopy = pasteboard.writeObjects([NSImage(cgImage: image, size: .zero)])
						#else
						didCopy = false
						#endif
						completion?(didCopy)
						continuation.resume()
					}
				}
			}
		}
	}
	#endif

	@MainActor
	func playerObserverHandler(
		status: AVPlayer.TimeControlStatus?,
		bgmItem: BangumiItemModel?,
		filename: String?,
		ep: EpisodeDetailModel?,
		isOffline: Bool,
		isBGMTVWatched: Bool,
		isFinalEpisode: Bool = false
	) {
		switch status {
		case nil:
			print("nothing is here")
		case .waitingToPlayAtSpecifiedRate:
			print("waiting")
			let shouldRecover = isPlaying || (avPlayer?.rate ?? 0) > 0
			isPlaying = false
			prefetchStreamingForwardBufferForPausedPlayback()
			if shouldRecover {
				scheduleStallRecovery()
			}
		case .paused:
			print("paused")
			if isRecoveringFromStall {
				isPlaying = false
				return
			}
			shouldResumeAfterStall = false
			isPlaying = false
			if let player = avPlayer {
				logPlaybackPosition(
					player: player,
					bgmItem: bgmItem,
					ep: ep,
					isOffline: isOffline,
					filename: filename,
					isBGMTVWatched: isBGMTVWatched,
					isFinalEpisode: isFinalEpisode
				)
			}
			prefetchStreamingForwardBufferForPausedPlayback()
		case .playing:
			print("playing")
			shouldResumeAfterStall = true
			stallRecoveryTask?.cancel()
			stallRecoveryTask = nil
			isPlaying = true
			prefetchStreamingForwardBuffer()
		case .some:
			print("unknown player status:\(String(describing: status))")
		@unknown default:
			print("unknown player status:\(String(describing: status))")
		}
	}

	@discardableResult
	@MainActor
	func logPlaybackPosition(
		player: AVPlayer,
		bgmItem: BangumiItemModel?,
		ep: EpisodeDetailModel?,
		isOffline: Bool,
		filename: String?,
		isBGMTVWatched: Bool,
		isFinalEpisode: Bool = false
	) -> PlaybackProgressSnapshot? {
		guard let currentItem = player.currentItem else { return nil }

		let currentTime = CMTimeGetSeconds(currentItem.currentTime())
		guard currentTime.isFinite else { return nil }
		let duration = CMTimeGetSeconds(currentItem.duration)
		var percent = duration.isFinite && duration > 0 ? currentTime / duration : 0
		if !percent.isFinite {
			percent = 0
		}

		let wasAlreadyFinished = ep?.watch_progress?.watch_status == 2
		let isFinished = wasAlreadyFinished || percent >= 0.95
		if wasAlreadyFinished, percent < 0.95 {
			print("Preserve watched episode status while updating replay progress: \(ep?.id ?? "unknown")")
		}
		let snapshot = PlaybackProgressSnapshot(
			position: currentTime,
			percentage: percent,
			isFinished: isFinished
		)

		let playbackLogKey = ep?.id ?? filename ?? "unknown"
		let now = Date()
		if lastPlaybackLogKey == playbackLogKey,
		   abs(lastPlaybackLogPosition - currentTime) < 1,
		   now.timeIntervalSince(lastPlaybackLogDate) < 5 {
			print("Skip duplicate playback progress log for \(playbackLogKey)")
			return snapshot
		}
		lastPlaybackLogKey = playbackLogKey
		lastPlaybackLogPosition = currentTime
		lastPlaybackLogDate = now
		print("logprogress:\(currentTime),\(percent)")

		if !isOffline {
			if let theEP = ep {
				if isFinished && !isBGMTVWatched {
					if let subject_id = theEP.bangumi?.bgm_id {
						if let episode_id = theEP.bgm_eps_id {
							print("save to BGM.TV as watched")
							setBGMSBEPStatues(
								subject_id: subject_id,
								episode_id: episode_id,
								status: 2
							) { result, data in
								print(data)
							}
						} else {
							print("ep.bgm_eps_id is missing")
						}
					} else {
						print("ep.bangumi.bgm_id is missing")
					}
				}

				if let bangumi_id = theEP.bangumi_id {
					print("save progress to albireo")
					sentAlbireoEPWatchProgress(
						ep_id: theEP.id,
						bangumi_id: bangumi_id,
						last_watch_position: currentTime,
						percentage: percent,
						is_finished: isFinished
					) { result, data in
						print(data as Any)
					}
				} else {
					print("ep.bangumi_id is missing")
				}

				if let item = bgmItem {
					savePlaybackHistory(item)

					if settingsHandler.getSetWatchedWhenFinishedFinalEP() && isFinished && isFinalEpisode {
						print("should set the subject/collection as watched: final episode finished")
						if item.favorite_status == 3 {
							changeFavStatus(
								idstr: item.id,
								bgmid: item.bgm_id ?? theEP.bangumi?.bgm_id,
								status: 2
							)
						} else {
							print("fav status is not watching. skip set as watched")
						}
					}
				}
			}
		} else {
			if let theFileName = filename {
				print("loging offline, filename is \(theFileName)")
				offlinePBM.setPlayBackStatus(
					item: OfflineVideoItem(
						epID: ep?.id ?? nil,
						bgm_eps_id: ep?.bgm_eps_id ?? nil,
						filename: theFileName,
						position: currentTime,
						isFinished: isFinished,
						bangumiName: ep?.bangumi?.name_cn?.isEmpty == false ? ep?.bangumi?.name_cn : ep?.bangumi?.name,
						episodeNo: ep?.episode_no,
						episodeName: ep?.name_cn?.isEmpty == false ? ep?.name_cn : ep?.name
					)
				)
			}
		}

		return snapshot
	}

	func setMatadata(ep: EpisodeDetailModel?) -> [AVMetadataItem] {
		var metadata: [AVMetadataItem] = []
		guard let ep else { return metadata }

		if let name = ep.name {
			metadata.append(createMetadataItem(for: .commonIdentifierTitle, value: name))
		}
		if let summary = ep.summary {
			metadata.append(createMetadataItem(for: .commonIdentifierDescription, value: summary))
		}
		if let imageURL = ep.thumbnail,
		   let url = resizedImageURL(
			fixPathNotCompete(path: imageURL),
			pixelWidth: 1200,
			pixelHeight: 675
		   ) {
			let rdata = try? Data(contentsOf: url)
			metadata.append(
				createMetadataItem(
					for: .commonIdentifierArtwork,
					value: rdata ?? NSNull()
				)
			)
		}
		if let subtitle = ep.name_cn {
			metadata.append(createMetadataItem(for: .iTunesMetadataTrackSubTitle, value: subtitle))
		}

		return metadata
	}

	func createMetadataItem(for identifier: AVMetadataIdentifier, value: Any) -> AVMetadataItem {
		let item = AVMutableMetadataItem()
		item.identifier = identifier
		item.value = value as? NSCopying & NSObjectProtocol
		item.extendedLanguageTag = "und"
		return item.copy() as! AVMetadataItem
	}

	func changeFavStatus(idstr: String?, bgmid: Int?, status: Int) {
		if let idstr1 = idstr {
			print("changing fav status to \(status)")
			changeAlbireoFavStatus(bangumi_id: idstr1, status: status, completion: { isSuccess, result in
				print(result as Any)
				if isSuccess {
					print("albireo fav status change success")
				}
			})
		}

		if let bgm_id = bgmid {
			setBGMCollectionStatus(subject_id: bgm_id, status: status) { isSuccess, result in
				print(result as Any)
				if isSuccess {
					print("setBGMCollectionStatus success")
				} else {
					print("setBGMCollectionStatus retrun false")
				}
			}
		} else {
			print("bgmid not found")
		}
	}

	@MainActor
	private func resetPlayerState() {
		avPlayer?.pause()
		removeTimeObserver()
		streamingFactory.stop(deleteCache: false)
		streamingCacheManager = nil
		currentTime = 0
		duration = 0
		isPlaying = false
		isSeeking = false
		playbackRate = settingsHandler.getPlaybackRate()
		loadedTimeRanges = []
		volume = avPlayer?.volume ?? 1.0
		stallRecoveryTask?.cancel()
		stallRecoveryTask = nil
		shouldResumeAfterStall = false
		lastStreamingPrefetchMaintenanceDate = nil
		cancellables.removeAll()
		itemCancellables.removeAll()
		isRecoveringFromStall = false
		currentStreamingURL = nil
	}

	@MainActor
	private func configureCurrentPlayer() {
		guard let player = avPlayer else { return }

		configurePlaybackAudioSession()
		player.currentItem?.preferredForwardBufferDuration = TimeInterval(120)
		player.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
		player.automaticallyWaitsToMinimizeStalling = true
		playbackRate = settingsHandler.getPlaybackRate()
		player.defaultRate = Float(playbackRate)
		volume = player.volume

		observePlayerItem(player.currentItem)
		addTimeObserver(to: player)

		player.publisher(for: \.timeControlStatus)
			.receive(on: RunLoop.main)
			.sink { [weak self] status in
				self?.isPlaying = status == .playing
			}
			.store(in: &cancellables)

		player.publisher(for: \.volume)
			.receive(on: RunLoop.main)
			.sink { [weak self] volume in
				self?.volume = volume
			}
			.store(in: &cancellables)
	}

	@MainActor
	private func configurePlaybackAudioSession() {
		#if os(iOS) || os(tvOS)
		let audioSession = AVAudioSession.sharedInstance()
		do {
			try audioSession.setCategory(.playback)
			try audioSession.setActive(true, options: [])
		} catch {
			print("Setting category to AVAudioSessionCategoryPlayback failed: \(error)")
		}
		#endif
	}

	@MainActor
	private func applyPlaybackRate() {
		guard let player = avPlayer else { return }
		player.defaultRate = Float(playbackRate)
		player.playImmediately(atRate: Float(playbackRate))
	}

	@MainActor
	private func observePlayerItem(_ item: AVPlayerItem?) {
		itemCancellables.removeAll()
		guard let item else { return }

		item.publisher(for: \.duration)
			.receive(on: RunLoop.main)
			.sink { [weak self] duration in
				let seconds = CMTimeGetSeconds(duration)
				if seconds.isFinite, seconds > 0 {
					self?.duration = seconds
				}
			}
			.store(in: &itemCancellables)

		item.publisher(for: \.loadedTimeRanges)
			.receive(on: RunLoop.main)
			.sink { [weak self] _ in
				self?.updateLoadedTimeRanges()
			}
			.store(in: &itemCancellables)

		NotificationCenter.default.publisher(for: .AVPlayerItemPlaybackStalled, object: item)
			.receive(on: RunLoop.main)
			.sink { [weak self] _ in
				self?.handlePlaybackStalled()
			}
			.store(in: &itemCancellables)
	}

	@MainActor
	private func addTimeObserver(to player: AVPlayer) {
		removeTimeObserver()

		let interval = CMTime(seconds: 0.25, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
		timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
			guard let self else { return }
			let seconds = CMTimeGetSeconds(time)
			if seconds.isFinite, !self.isSeeking {
				self.currentTime = seconds
			}

			if let itemDuration = player.currentItem?.duration {
				let duration = CMTimeGetSeconds(itemDuration)
				if duration.isFinite, duration > 0 {
					self.duration = duration
				}
			}

			self.updateLoadedTimeRanges()
			self.maintainStreamingForwardBufferIfNeeded()
		}
	}

	@MainActor
	private func updateLoadedTimeRanges() {
		if let streamingCacheManager {
			let cacheDuration = playerDuration()
			let ranges = streamingCacheManager.cachedTimeRanges(
				currentTime: playerCurrentTime(),
				duration: cacheDuration
			)
			if !ranges.isEmpty {
				loadedTimeRanges = ranges
				return
			}
		}

		guard let item = avPlayer?.currentItem else {
			loadedTimeRanges = []
			return
		}

		loadedTimeRanges = item.loadedTimeRanges.compactMap { value in
			let range = value.timeRangeValue
			let start = CMTimeGetSeconds(range.start)
			let end = CMTimeGetSeconds(range.start + range.duration)

			guard start.isFinite, end.isFinite, end > start else {
				return nil
			}

			return start...end
		}
	}

	@MainActor
	private func handlePlaybackStalled() {
		print("playback stalled")
		if let player = avPlayer, let item = player.currentItem {
			let waitingReason = player.reasonForWaitingToPlay?.rawValue ?? "none"
			let itemError = item.error?.localizedDescription ?? "none"
			print(
				"AVPlayer stalled snapshot: timeControlStatus=\(player.timeControlStatus.rawValue), " +
				"waitingReason=\(waitingReason), itemStatus=\(item.status.rawValue), itemError=\(itemError)"
			)
		}
		if let streamingCacheManager {
			print(
				"Streaming cache stalled snapshot: \(streamingCacheManager.debugSummary(currentTime: playerCurrentTime(), duration: playerDuration()))"
			)
		}
		prefetchStreamingForwardBufferForPausedPlayback()
		if shouldResumeAfterStall {
			scheduleStallRecovery()
		}
	}

	@MainActor
	private func prefetchStreamingForwardBuffer() {
		streamingCacheManager?.prefetchForwardBuffer(
			currentTime: playerCurrentTime(),
			duration: playerDuration()
		)
	}

	@MainActor
	private func prefetchStreamingForwardBufferForPausedPlayback() {
		streamingCacheManager?.prefetchPausedForwardBuffer(
			currentTime: playerCurrentTime(),
			duration: playerDuration()
		)
	}

	@MainActor
	private func maintainStreamingForwardBufferIfNeeded() {
		guard streamingCacheManager != nil else { return }

		let now = Date()
		if let lastStreamingPrefetchMaintenanceDate,
		   now.timeIntervalSince(lastStreamingPrefetchMaintenanceDate) < 2 {
			return
		}

		lastStreamingPrefetchMaintenanceDate = now
		if isPlaying || avPlayer?.timeControlStatus == .playing {
			prefetchStreamingForwardBuffer()
		}
	}

	@MainActor
	private func playerCurrentTime() -> Double? {
		guard let player = avPlayer else { return nil }
		let seconds = CMTimeGetSeconds(player.currentTime())
		return seconds.isFinite ? seconds : nil
	}

	@MainActor
	private func playerDuration() -> Double? {
		if duration.isFinite, duration > 0 {
			return duration
		}

		guard let itemDuration = avPlayer?.currentItem?.duration else {
			return nil
		}

		let seconds = CMTimeGetSeconds(itemDuration)
		return seconds.isFinite && seconds > 0 ? seconds : nil
	}

	@MainActor
	private func scheduleStallRecovery() {
		guard stallRecoveryTask == nil, !isRecoveringFromStall else { return }

		stallRecoveryTask?.cancel()
		stallRecoveryTask = Task { @MainActor [weak self] in
			try? await Task.sleep(nanoseconds: 900_000_000)
			guard let self else { return }
			self.stallRecoveryTask = nil
			guard self.shouldResumeAfterStall, let player = self.avPlayer else { return }
			guard player.timeControlStatus != .playing else { return }

			self.rebuildStreamingPlayerItem(afterStallAt: player.currentTime())
		}
	}

	@MainActor
	private func rebuildStreamingPlayerItem(afterStallAt stalledTime: CMTime) {
		guard !isRecoveringFromStall,
			  let player = avPlayer,
			  let currentStreamingURL,
			  streamingCacheManager != nil else {
			applyPlaybackRate()
			return
		}

		isRecoveringFromStall = true
		let stalledSeconds = max(0, CMTimeGetSeconds(stalledTime))
		let resumeSeconds = stalledSeconds.isFinite ? max(0, stalledSeconds - 10) : 0
		let resumeTime = CMTime(
			seconds: resumeSeconds,
			preferredTimescale: Int32(NSEC_PER_SEC)
		)
		#if os(iOS) || os(tvOS) || os(visionOS)
		let metadata = player.currentItem?.externalMetadata ?? []
		#endif

		do {
			let replacementItem = try streamingFactory.makeReplacementPlayerItem(for: currentStreamingURL)
			#if os(iOS) || os(tvOS) || os(visionOS)
			replacementItem.externalMetadata = metadata
			#endif
			replacementItem.preferredForwardBufferDuration = TimeInterval(120)
			replacementItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true

			itemCancellables.removeAll()
			player.pause()
			player.cancelPendingPrerolls()
			player.replaceCurrentItem(with: replacementItem)
			observePlayerItem(replacementItem)

			replacementItem.publisher(for: \.status)
				.receive(on: RunLoop.main)
				.filter { $0 != .unknown }
				.prefix(1)
				.sink { [weak self, weak player, weak replacementItem] status in
					guard let self, let player, let replacementItem,
						  player.currentItem === replacementItem else { return }
					guard status == .readyToPlay else {
						self.isRecoveringFromStall = false
						print("Streaming stall recovery item failed: \(replacementItem.error?.localizedDescription ?? "unknown")")
						return
					}

					self.isSeeking = true
					let toleranceBefore = CMTime(seconds: 5, preferredTimescale: 600)
					let toleranceAfter = CMTime(seconds: 2, preferredTimescale: 600)
					player.seek(
						to: resumeTime,
						toleranceBefore: toleranceBefore,
						toleranceAfter: toleranceAfter
					) { [weak self, weak player] finished in
						Task { @MainActor in
							guard let self, let player else { return }
							self.isSeeking = false
							self.currentTime = CMTimeGetSeconds(player.currentTime())
							guard finished, self.shouldResumeAfterStall else {
								self.isRecoveringFromStall = false
								return
							}
							self.prefetchStreamingForwardBuffer()
							player.preroll(atRate: Float(self.playbackRate)) { [weak self] _ in
								Task { @MainActor in
									guard let self else { return }
									self.isRecoveringFromStall = false
									guard self.shouldResumeAfterStall else { return }
									self.applyPlaybackRate()
								}
							}
						}
					}
				}
				.store(in: &itemCancellables)
		} catch {
			isRecoveringFromStall = false
			print("Streaming stall recovery could not rebuild player item: \(error)")
			applyPlaybackRate()
		}
	}

	@MainActor
	private func removeTimeObserver() {
		guard let token = timeObserverToken, let player = avPlayer else {
			timeObserverToken = nil
			return
		}

		player.removeTimeObserver(token)
		timeObserverToken = nil
	}
}
