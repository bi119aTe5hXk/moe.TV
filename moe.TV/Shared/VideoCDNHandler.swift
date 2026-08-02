//
//  VideoCDNHandler.swift
//  moe.TV
//
//  Handles video CDN node discovery and playback URL selection.
//

import Foundation

private let videoCDNSettingsHandler = SettingsHandler()

func getVideoCDNOptions(videoURLString: String,
						includeLatency: Bool = false,
						completion: @escaping (Bool, Any) -> Void) {
	guard let url = URL(string: videoURLString) else {
		completion(false, "Invalid video URL: \(videoURLString)")
		return
	}

	postVideoCDNRequest(url: url, groupName: nil) { result in
		switch result {
		case .success(let response):
			guard let data = response.data else {
				completion(false, "Video CDN response is empty.")
				return
			}
			do {
				let options = try JSONDecoder().decode([VideoCDNOption].self, from: data)
				if includeLatency {
					measureVideoCDNLatency(options: options) { measuredOptions in
						videoCDNSettingsHandler.setVideoCDNOptions(measuredOptions)
						completion(true, measuredOptions)
					}
				} else {
					videoCDNSettingsHandler.setVideoCDNOptions(options)
					completion(true, options)
				}
			} catch {
				let responseText = String(data: data, encoding: .utf8) ?? ""
				completion(false, "Video CDN decode failed: \(error.localizedDescription), response: \(responseText)")
			}
		case .failure(let message):
			completion(false, message)
		}
	}
}

func updateVideoCDNOptionLatencies(_ options: [VideoCDNOption],
								   completion: @escaping ([VideoCDNOption]) -> Void) {
	measureVideoCDNLatency(options: options, completion: completion)
}

func refreshVideoCDNOptionsFromFirstPlayableEpisode(completion: @escaping (Bool, Any) -> Void) {
	videoCDNSettingsHandler.registerSettings()
	let authMode = videoCDNSettingsHandler.getAlbireoAuthMode()
	print("Video CDN refresh started, auth mode: \(authMode)")
	switch authMode {
	case .albireoV2OAuth:
		refreshVideoCDNOptionsFromAlbireoV2Sample(completion: completion)
	case .legacyCookie:
		refreshVideoCDNOptionsFromLegacyAlbireoSample(completion: completion)
	}
}

private func failVideoCDNRefresh(_ message: String,
								 completion: @escaping (Bool, Any) -> Void) {
	print("Video CDN refresh failed: \(message)")
	completion(false, message)
}

func resolveVideoCDNPlaybackURL(_ videoURLString: String,
								completion: @escaping (String, String?) -> Void) {
	videoCDNSettingsHandler.registerSettings()
	let selectedGroup = videoCDNSettingsHandler.getVideoCDNGroup().trimmingCharacters(in: .whitespacesAndNewlines)
	guard !selectedGroup.isEmpty else {
		clearVideoCDNPlaybackCookie(for: URL(string: videoURLString))
		completion(videoURLString, nil)
		return
	}

	getVideoCDNOptions(videoURLString: videoURLString) { isSuccess, data in
		if isSuccess, let options = data as? [VideoCDNOption] {
			guard let selectedOption = options.first(where: { $0.name == selectedGroup }),
				  selectedOption.isSelectable else {
				switchVideoCDNToAutomatic(for: URL(string: videoURLString))
				completion(videoURLString, "Selected video CDN is unavailable. Switched to automatic CDN.")
				return
			}
		} else {
			print("Video CDN list refresh failed before playback: \(data)")
		}

		guard let url = URL(string: videoURLString) else {
			completion(videoURLString, "Invalid video URL. Switched to original URL.")
			return
		}

		postVideoCDNRequest(url: url, groupName: selectedGroup) { result in
			switch result {
			case .success:
				applyVideoCDNPlaybackCookie(groupName: selectedGroup, for: url)
				completion(videoURLString, nil)
			case .failure(let message):
				switchVideoCDNToAutomatic(for: url)
				completion(videoURLString, "\(message) Switched to automatic CDN.")
			}
		}
	}
}

private func switchVideoCDNToAutomatic(for url: URL?) {
	videoCDNSettingsHandler.setVideoCDNGroup("")
	clearVideoCDNPlaybackCookie(for: url)
	DispatchQueue.main.async {
		NotificationCenter.default.post(name: .videoCDNSettingsDidChange, object: nil)
	}
}

func videoCDNHTTPHeaderFields(for url: URL) -> [String: String] {
	videoCDNSettingsHandler.registerSettings()
	let selectedGroup = videoCDNSettingsHandler.getVideoCDNGroup().trimmingCharacters(in: .whitespacesAndNewlines)
	guard !selectedGroup.isEmpty else {
		return [:]
	}
	return ["Cookie": "group=\(selectedGroup)"]
}

private func applyVideoCDNPlaybackCookie(groupName: String, for url: URL) {
	guard let host = url.host, !groupName.isEmpty else { return }
	clearVideoCDNPlaybackCookie(for: url)

	let properties: [HTTPCookiePropertyKey: Any] = [
		.domain: host,
		.path: "/video",
		.name: "group",
		.value: groupName,
		.secure: url.scheme == "https",
		.expires: Date(timeIntervalSinceNow: 60 * 60)
	]

	if let cookie = HTTPCookie(properties: properties) {
		HTTPCookieStorage.shared.setCookie(cookie)
	}
}

private func clearVideoCDNPlaybackCookie(for url: URL?) {
	guard let url, let host = url.host else { return }
	HTTPCookieStorage.shared.cookies?
		.filter { $0.name == "group" && $0.domain == host }
		.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
}

private func refreshVideoCDNOptionsFromAlbireoV2Sample(completion: @escaping (Bool, Any) -> Void) {
	getAlbireoV2OnAirList { isSuccess, data in
		guard isSuccess, let responseData = data as? Data else {
			failVideoCDNRefresh("Failed to load Albireo V2 on-air list: \(data)", completion: completion)
			return
		}
		do {
			let bangumiList = try decodeAlbireoV2BangumiItems(from: responseData)
			guard !bangumiList.isEmpty else {
				failVideoCDNRefresh("Albireo V2 on-air list is empty.", completion: completion)
				return
			}
			tryAlbireoV2BangumiForVideoCDN(
				bangumiList,
				bangumiIndex: 0,
				completion: completion
			)
		} catch {
			failVideoCDNRefresh("Albireo V2 on-air list decode failed: \(error.localizedDescription)", completion: completion)
		}
	}
}

private func tryAlbireoV2BangumiForVideoCDN(
	_ bangumiList: [BangumiItemModel],
	bangumiIndex: Int,
	completion: @escaping (Bool, Any) -> Void
) {
	guard bangumiIndex < bangumiList.count else {
		failVideoCDNRefresh("No playable episode with a video URL was found in the Albireo V2 on-air list.", completion: completion)
		return
	}

	let bangumi = bangumiList[bangumiIndex]
	print("Video CDN refresh checking Albireo V2 bangumi [\(bangumiIndex + 1)/\(bangumiList.count)]: \(bangumi.id)")
	getAlbireoV2BangumiDetail(id: bangumi.id) { isSuccess, data in
		guard isSuccess, let responseData = data as? Data,
			  let detail = try? decodeAlbireoV2BangumiDetail(from: responseData) else {
			print("Video CDN refresh skipped Albireo V2 bangumi \(bangumi.id): detail request or decode failed.")
			tryAlbireoV2BangumiForVideoCDN(
				bangumiList,
				bangumiIndex: bangumiIndex + 1,
				completion: completion
			)
			return
		}

		let episodes = detail.episodes?.filter { $0.status == 2 } ?? []
		guard !episodes.isEmpty else {
			print("Video CDN refresh skipped Albireo V2 bangumi \(bangumi.id): no episode with status == 2.")
			tryAlbireoV2BangumiForVideoCDN(
				bangumiList,
				bangumiIndex: bangumiIndex + 1,
				completion: completion
			)
			return
		}

		tryAlbireoV2EpisodeForVideoCDN(
			episodes,
			episodeIndex: 0,
			bangumiID: detail.id
		) { videoURL in
			guard let videoURL else {
				print("Video CDN refresh skipped Albireo V2 bangumi \(bangumi.id): playable episodes have no video URL.")
				tryAlbireoV2BangumiForVideoCDN(
					bangumiList,
					bangumiIndex: bangumiIndex + 1,
					completion: completion
				)
				return
			}
			print("Video CDN refresh resolved Albireo V2 video URL: \(videoURL)")
			getVideoCDNOptions(videoURLString: videoURL, includeLatency: true, completion: completion)
		}
	}
}

private func tryAlbireoV2EpisodeForVideoCDN(
	_ episodes: [BGMEpisode],
	episodeIndex: Int,
	bangumiID: String,
	completion: @escaping (String?) -> Void
) {
	guard episodeIndex < episodes.count else {
		completion(nil)
		return
	}

	let episode = episodes[episodeIndex]
	print("Video CDN refresh checking Albireo V2 episode: \(episode.id), status: \(episode.status)")
	getAlbireoV2EpisodeDetail(epID: episode.id, defaultBangumiID: bangumiID) { isSuccess, data in
		if isSuccess,
		   let detail = data as? EpisodeDetailModel,
		   let videoURL = detail.video_files?.first?.url,
		   !videoURL.isEmpty {
			completion(fixPathNotCompete(path: videoURL))
			return
		}
		tryAlbireoV2EpisodeForVideoCDN(
			episodes,
			episodeIndex: episodeIndex + 1,
			bangumiID: bangumiID,
			completion: completion
		)
	}
}

private func refreshVideoCDNOptionsFromLegacyAlbireoSample(completion: @escaping (Bool, Any) -> Void) {
	getAlbireoOnAirList { isSuccess, data in
		guard isSuccess, let bangumiList = data as? [BangumiItemModel], !bangumiList.isEmpty else {
			failVideoCDNRefresh("Failed to load Albireo V1 on-air list: \(String(describing: data))", completion: completion)
			return
		}
		tryLegacyAlbireoBangumiForVideoCDN(
			bangumiList,
			bangumiIndex: 0,
			completion: completion
		)
	}
}

private func tryLegacyAlbireoBangumiForVideoCDN(
	_ bangumiList: [BangumiItemModel],
	bangumiIndex: Int,
	completion: @escaping (Bool, Any) -> Void
) {
	guard bangumiIndex < bangumiList.count else {
		failVideoCDNRefresh("No playable episode with a video URL was found in the Albireo V1 on-air list.", completion: completion)
		return
	}

	let bangumi = bangumiList[bangumiIndex]
	print("Video CDN refresh checking Albireo V1 bangumi [\(bangumiIndex + 1)/\(bangumiList.count)]: \(bangumi.id)")
	getAlbireoBangumiDetail(id: bangumi.id) { isSuccess, data in
		guard isSuccess, let detail = data as? BangumiDetailModel else {
			print("Video CDN refresh skipped Albireo V1 bangumi \(bangumi.id): detail request failed.")
			tryLegacyAlbireoBangumiForVideoCDN(
				bangumiList,
				bangumiIndex: bangumiIndex + 1,
				completion: completion
			)
			return
		}

		let episodes = detail.episodes?.filter { $0.status == 2 } ?? []
		guard !episodes.isEmpty else {
			print("Video CDN refresh skipped Albireo V1 bangumi \(bangumi.id): no episode with status == 2.")
			tryLegacyAlbireoBangumiForVideoCDN(
				bangumiList,
				bangumiIndex: bangumiIndex + 1,
				completion: completion
			)
			return
		}

		tryLegacyAlbireoEpisodeForVideoCDN(episodes, episodeIndex: 0) { videoURL in
			guard let videoURL else {
				print("Video CDN refresh skipped Albireo V1 bangumi \(bangumi.id): playable episodes have no video URL.")
				tryLegacyAlbireoBangumiForVideoCDN(
					bangumiList,
					bangumiIndex: bangumiIndex + 1,
					completion: completion
				)
				return
			}
			print("Video CDN refresh resolved Albireo V1 video URL: \(videoURL)")
			getVideoCDNOptions(videoURLString: videoURL, includeLatency: true, completion: completion)
		}
	}
}

private func tryLegacyAlbireoEpisodeForVideoCDN(
	_ episodes: [BGMEpisode],
	episodeIndex: Int,
	completion: @escaping (String?) -> Void
) {
	guard episodeIndex < episodes.count else {
		completion(nil)
		return
	}

	let episode = episodes[episodeIndex]
	print("Video CDN refresh checking Albireo V1 episode: \(episode.id), status: \(episode.status)")
	getAlbireoEPDetail(ep_id: episode.id) { isSuccess, data in
		if isSuccess,
		   let detail = data as? EpisodeDetailModel,
		   let videoURL = detail.video_files?.first?.url,
		   !videoURL.isEmpty {
			completion(fixPathNotCompete(path: videoURL))
			return
		}
		tryLegacyAlbireoEpisodeForVideoCDN(
			episodes,
			episodeIndex: episodeIndex + 1,
			completion: completion
		)
	}
}

private struct VideoCDNPOSTResponse {
	let data: Data?
	let redirectURL: URL?
}

private enum VideoCDNPOSTResult {
	case success(VideoCDNPOSTResponse)
	case failure(String)
}

private func logVideoCDNPOSTRequest(_ request: URLRequest, requestID: String) {
	print("Video CDN POST [\(requestID)] URL: \(request.url?.absoluteString ?? "<invalid>")")

	guard let body = request.httpBody, !body.isEmpty else {
		print("Video CDN POST [\(requestID)] body: <empty>")
		return
	}

	if let object = try? JSONSerialization.jsonObject(with: body),
	   let formattedData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
	   let formattedBody = String(data: formattedData, encoding: .utf8) {
		print("Video CDN POST [\(requestID)] body (JSON):\n\(formattedBody)")
	} else if let bodyText = String(data: body, encoding: .utf8) {
		print("Video CDN POST [\(requestID)] body:\n\(bodyText)")
	} else {
		print("Video CDN POST [\(requestID)] body: <\(body.count) non-text bytes>")
	}
}

private final class VideoCDNRedirectBlocker: NSObject, URLSessionTaskDelegate {
	private let onRedirect: (URL) -> Void

	init(onRedirect: @escaping (URL) -> Void) {
		self.onRedirect = onRedirect
	}

	func urlSession(_ session: URLSession,
					task: URLSessionTask,
					willPerformHTTPRedirection response: HTTPURLResponse,
					newRequest request: URLRequest,
					completionHandler: @escaping (URLRequest?) -> Void) {
		if let url = request.url {
			onRedirect(url)
		}
		completionHandler(nil)
	}
}

private func postVideoCDNRequest(url: URL,
								 groupName: String?,
								 completion: @escaping (VideoCDNPOSTResult) -> Void) {
	var redirectURL: URL?
	let delegate = VideoCDNRedirectBlocker { url in
		redirectURL = url
	}
	let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)
	var request = URLRequest(url: url)
	request.httpMethod = "POST"
	request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
	request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
	if let groupName, !groupName.isEmpty {
		request.setValue("group=\(groupName)", forHTTPHeaderField: "Cookie")
	}
	videoCDNSettingsHandler.registerSettings()
	let accessToken = videoCDNSettingsHandler.getAlbireoV2AccessToken()
	if !accessToken.isEmpty {
		request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
	}
	let requestID = String(UUID().uuidString.prefix(8))
	logVideoCDNPOSTRequest(request, requestID: requestID)

	session.dataTask(with: request) { data, response, error in
		defer {
			session.finishTasksAndInvalidate()
		}
		if let error {
			print("Video CDN POST [\(requestID)] transport error: \(error.localizedDescription)")
			completion(.failure(error.localizedDescription))
			return
		}
		if let redirectURL {
			print("Video CDN POST [\(requestID)] redirect: \(redirectURL.absoluteString)")
			completion(.success(VideoCDNPOSTResponse(data: data, redirectURL: redirectURL)))
			return
		}
		if let httpResponse = response as? HTTPURLResponse {
			print("Video CDN POST [\(requestID)] status: \(httpResponse.statusCode)")
			if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
				let responseText = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
				completion(.failure("Video CDN POST HTTP \(httpResponse.statusCode): \(responseText)"))
				return
			}
		}
		completion(.success(VideoCDNPOSTResponse(data: data, redirectURL: nil)))
	}.resume()
}

private func measureVideoCDNLatency(options: [VideoCDNOption],
									completion: @escaping ([VideoCDNOption]) -> Void) {
	var measuredOptions = options
	let group = DispatchGroup()
	let lock = NSLock()

	for (index, option) in options.enumerated() {
		guard option.isSelectable, let urlString = option.url, let url = URL(string: urlString) else {
			continue
		}
		group.enter()
		let start = Date()
		var request = URLRequest(url: url)
		request.httpMethod = "HEAD"
		request.timeoutInterval = 4
		URLSession.shared.dataTask(with: request) { _, _, _ in
			let latency = max(1, Int(Date().timeIntervalSince(start) * 1000))
			lock.lock()
			measuredOptions[index].latencyMS = latency
			lock.unlock()
			group.leave()
		}.resume()
	}

	group.notify(queue: .global()) {
		completion(measuredOptions)
	}
}
