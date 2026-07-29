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
	switch videoCDNSettingsHandler.getAlbireoAuthMode() {
	case .albireoV2OAuth:
		refreshVideoCDNOptionsFromAlbireoV2Sample(completion: completion)
	case .legacyCookie:
		refreshVideoCDNOptionsFromLegacyAlbireoSample(completion: completion)
	}
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
			completion(false, "Failed to load Albireo V2 on-air list for CDN refresh: \(data)")
			return
		}
		do {
			let bangumiList = try decodeAlbireoV2BangumiItems(from: responseData)
			guard let bangumi = bangumiList.first else {
				completion(false, "Albireo V2 on-air list is empty.")
				return
			}
			getAlbireoV2BangumiDetail(id: bangumi.id) { isDetailSuccess, detailData in
				guard isDetailSuccess, let detailResponseData = detailData as? Data else {
					completion(false, "Failed to load Albireo V2 bangumi detail for CDN refresh: \(detailData)")
					return
				}
				do {
					let detail = try decodeAlbireoV2BangumiDetail(from: detailResponseData)
					guard let episode = detail.episodes?.first else {
						completion(false, "Albireo V2 bangumi detail has no episodes for CDN refresh.")
						return
					}
					getAlbireoV2EpisodeDetail(epID: episode.id, defaultBangumiID: detail.id) { isEpisodeSuccess, episodeData in
						guard isEpisodeSuccess, let episodeDetail = episodeData as? EpisodeDetailModel else {
							completion(false, "Failed to load Albireo V2 episode detail for CDN refresh: \(episodeData)")
							return
						}
						guard let videoURL = episodeDetail.video_files?.first?.url, !videoURL.isEmpty else {
							completion(false, "Albireo V2 episode detail has no video URL for CDN refresh.")
							return
						}
						getVideoCDNOptions(videoURLString: fixPathNotCompete(path: videoURL), includeLatency: true, completion: completion)
					}
				} catch {
					completion(false, "Albireo V2 bangumi detail decode failed for CDN refresh: \(error.localizedDescription)")
				}
			}
		} catch {
			completion(false, "Albireo V2 on-air list decode failed for CDN refresh: \(error.localizedDescription)")
		}
	}
}

private func refreshVideoCDNOptionsFromLegacyAlbireoSample(completion: @escaping (Bool, Any) -> Void) {
	getAlbireoOnAirList { isSuccess, data in
		guard isSuccess, let bangumiList = data as? [BangumiItemModel], let bangumi = bangumiList.first else {
			completion(false, "Failed to load Albireo on-air list for CDN refresh: \(String(describing: data))")
			return
		}
		getAlbireoBangumiDetail(id: bangumi.id) { isDetailSuccess, detailData in
			guard isDetailSuccess, let detail = detailData as? BangumiDetailModel, let episode = detail.episodes?.first else {
				completion(false, "Failed to load Albireo bangumi detail for CDN refresh: \(String(describing: detailData))")
				return
			}
			getAlbireoEPDetail(ep_id: episode.id) { isEpisodeSuccess, episodeData in
				guard isEpisodeSuccess, let episodeDetail = episodeData as? EpisodeDetailModel else {
					completion(false, "Failed to load Albireo episode detail for CDN refresh: \(String(describing: episodeData))")
					return
				}
				guard let videoURL = episodeDetail.video_files?.first?.url, !videoURL.isEmpty else {
					completion(false, "Albireo episode detail has no video URL for CDN refresh.")
					return
				}
				getVideoCDNOptions(videoURLString: fixPathNotCompete(path: videoURL), includeLatency: true, completion: completion)
			}
		}
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

	session.dataTask(with: request) { data, response, error in
		defer {
			session.finishTasksAndInvalidate()
		}
		if let error {
			completion(.failure(error.localizedDescription))
			return
		}
		if let redirectURL {
			completion(.success(VideoCDNPOSTResponse(data: data, redirectURL: redirectURL)))
			return
		}
		if let httpResponse = response as? HTTPURLResponse,
		   httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
			let responseText = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
			completion(.failure("Video CDN POST HTTP \(httpResponse.statusCode): \(responseText)"))
			return
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
