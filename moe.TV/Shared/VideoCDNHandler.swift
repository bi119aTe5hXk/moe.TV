//
//  VideoCDNHandler.swift
//  moe.TV
//
//  Handles video CDN node discovery and playback URL selection.
//

import Foundation

private let videoCDNSettingsHandler = SettingsHandler()
private let videoCDNRouteQueryName = "__mira_route"

private struct VideoCDNBackendCatalog: Decodable {
	let version: Int
	let backends: [VideoCDNOption]
}

private struct VideoCDNRouteRequest: Encodable {
	let resource: String
	let preference: VideoCDNRoutePreference
	let excludeBackendIds: [String]
}

private struct VideoCDNRoutePreference: Encodable {
	let mode: String
	let backendId: String?
}

private struct VideoCDNRouteResponse: Decodable {
	struct Selection: Decodable {
		let mode: String
		let reason: String?
	}

	let routeToken: String
	let playbackUrl: String
	let selectedBackend: VideoCDNOption
	let selection: Selection
	let issuedAt: String?
	let freshUntil: String?
	let expiresAt: String?
}

private enum VideoCDNRoutingError: LocalizedError {
	case invalidURL
	case invalidResponse
	case invalidPlaybackURL
	case httpStatus(Int, String)
	case transport(String)

	var errorDescription: String? {
		switch self {
		case .invalidURL:
			return "Invalid canonical video URL."
		case .invalidResponse:
			return "Signed routing returned an invalid response."
		case .invalidPlaybackURL:
			return "Signed routing returned an invalid playback URL."
		case let .httpStatus(status, message):
			return message.isEmpty ? "Signed routing HTTP \(status)." : "Signed routing HTTP \(status): \(message)"
		case .transport(let message):
			return "Signed routing request failed: \(message)"
		}
	}
}

func getVideoCDNOptions(videoURLString: String,
						includeLatency _: Bool = false,
						completion: @escaping (Bool, Any) -> Void) {
	guard let canonicalURL = canonicalVideoCDNURL(from: videoURLString),
		  let endpoint = videoCDNRoutingEndpoint(path: "/_mira/routing/v1/backends", for: canonicalURL) else {
		completion(false, "Invalid video URL: \(videoURLString)")
		return
	}

	var request = URLRequest(url: endpoint)
	request.httpMethod = "GET"
	request.timeoutInterval = 3
	request.setValue("application/json", forHTTPHeaderField: "Accept")
	request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
	print("Video CDN backend catalog request: origin=\(videoCDNOriginDescription(canonicalURL))")

	videoCDNRoutingSession().dataTask(with: request) { data, response, error in
		if let error {
			completion(false, "Video CDN backend catalog failed: \(error.localizedDescription)")
			return
		}
		guard let http = response as? HTTPURLResponse,
			  http.statusCode == 200,
			  let data else {
			let status = (response as? HTTPURLResponse)?.statusCode ?? -1
			completion(false, "Video CDN backend catalog HTTP \(status).")
			return
		}

		do {
			let catalog = try JSONDecoder().decode(VideoCDNBackendCatalog.self, from: data)
			guard catalog.version == 1 else {
				completion(false, "Unsupported video CDN routing version: \(catalog.version)")
				return
			}
			videoCDNSettingsHandler.setVideoCDNOptions(catalog.backends)
			print("Video CDN backend catalog loaded: count=\(catalog.backends.count)")
			completion(true, catalog.backends)
		} catch {
			completion(false, "Video CDN backend catalog decode failed: \(error.localizedDescription)")
		}
	}.resume()
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
	guard let canonicalURL = canonicalVideoCDNURL(from: videoURLString) else {
		completion(videoURLString, "Invalid video URL. Switched to original URL.")
		return
	}
	let preferredBackendID = videoCDNSettingsHandler.getVideoCDNBackendID()
		.trimmingCharacters(in: .whitespacesAndNewlines)

	createVideoCDNRoute(canonicalURL: canonicalURL, preferredBackendID: preferredBackendID) { result in
		switch result {
		case .success(let route):
			clearVideoCDNPlaybackCookie(for: canonicalURL)
			logVideoCDNRoute(route)
			completion(route.playbackUrl, nil)
		case .failure(.httpStatus(422, _)) where !preferredBackendID.isEmpty:
			print("Video CDN preferred backend rejected: id=\(preferredBackendID); retrying automatic selection")
			switchVideoCDNToAutomatic(for: canonicalURL)
			createVideoCDNRoute(canonicalURL: canonicalURL, preferredBackendID: "") { retryResult in
				switch retryResult {
				case .success(let route):
					logVideoCDNRoute(route)
					completion(route.playbackUrl, "Selected video CDN is unavailable. Switched to automatic CDN.")
				case .failure(let error):
					print("Video CDN automatic route fallback: \(error.localizedDescription)")
					completion(canonicalURL.absoluteString, "Selected video CDN is unavailable. Switched to automatic CDN.")
				}
			}
		case .failure(let error):
			print("Video CDN signed route unavailable; using canonical URL. \(error.localizedDescription)")
			if !preferredBackendID.isEmpty {
				applyVideoCDNPlaybackCookie(backendID: preferredBackendID, for: canonicalURL)
				print("Video CDN legacy cookie fallback enabled: backendID=\(preferredBackendID)")
			} else {
				clearVideoCDNPlaybackCookie(for: canonicalURL)
			}
			completion(canonicalURL.absoluteString, nil)
		}
	}
}

private func switchVideoCDNToAutomatic(for url: URL?) {
	videoCDNSettingsHandler.setVideoCDNBackendID("")
	clearVideoCDNPlaybackCookie(for: url)
	DispatchQueue.main.async {
		NotificationCenter.default.post(name: .videoCDNSettingsDidChange, object: nil)
	}
}

func videoCDNHTTPHeaderFields(for url: URL) -> [String: String] {
	videoCDNSettingsHandler.registerSettings()
	guard !videoCDNURLContainsSignedRoute(url) else {
		return [:]
	}
	let backendID = videoCDNSettingsHandler.getVideoCDNBackendID().trimmingCharacters(in: .whitespacesAndNewlines)
	guard !backendID.isEmpty else {
		return [:]
	}
	return ["Cookie": "group=\(backendID)"]
}

func redactedVideoCDNURLDescription(_ url: URL) -> String {
	guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
		  let queryItems = components.queryItems,
		  queryItems.contains(where: { $0.name == videoCDNRouteQueryName }) else {
		return url.absoluteString
	}
	components.queryItems = queryItems.map { item in
		item.name == videoCDNRouteQueryName
			? URLQueryItem(name: item.name, value: "<redacted>")
			: item
	}
	return components.string ?? "<signed video URL>"
}

private func applyVideoCDNPlaybackCookie(backendID: String, for url: URL) {
	guard let host = url.host, !backendID.isEmpty else { return }
	clearVideoCDNPlaybackCookie(for: url)

	let properties: [HTTPCookiePropertyKey: Any] = [
		.domain: host,
		.path: "/",
		.name: "group",
		.value: backendID,
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
		guard isSuccess, let bangumiList = data as? [BangumiItemModel] else {
			failVideoCDNRefresh("Failed to load Albireo V2 on-air list: \(data)", completion: completion)
			return
		}
		guard !bangumiList.isEmpty else {
			failVideoCDNRefresh("Albireo V2 on-air list is empty.", completion: completion)
			return
		}
		tryAlbireoV2BangumiForVideoCDN(
			bangumiList,
			bangumiIndex: 0,
			completion: completion
		)
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
		guard isSuccess, let detail = data as? BangumiDetailModel else {
			print("Video CDN refresh skipped Albireo V2 bangumi \(bangumi.id): detail request failed.")
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

private func createVideoCDNRoute(
	canonicalURL: URL,
	preferredBackendID: String,
	completion: @escaping (Result<VideoCDNRouteResponse, VideoCDNRoutingError>) -> Void
) {
	guard let endpoint = videoCDNRoutingEndpoint(path: "/_mira/routing/v1/routes", for: canonicalURL),
		  let components = URLComponents(url: canonicalURL, resolvingAgainstBaseURL: false) else {
		completion(.failure(.invalidURL))
		return
	}

	let resource = components.percentEncodedQuery.map {
		"\(components.percentEncodedPath)?\($0)"
	} ?? components.percentEncodedPath
	let preference = VideoCDNRoutePreference(
		mode: preferredBackendID.isEmpty ? "auto" : "backend",
		backendId: preferredBackendID.isEmpty ? nil : preferredBackendID
	)
	let body = VideoCDNRouteRequest(
		resource: resource,
		preference: preference,
		excludeBackendIds: []
	)

	guard let bodyData = try? JSONEncoder().encode(body) else {
		completion(.failure(.invalidResponse))
		return
	}

	var request = URLRequest(url: endpoint)
	request.httpMethod = "POST"
	request.timeoutInterval = 2.5
	request.httpBody = bodyData
	request.setValue("application/json", forHTTPHeaderField: "Accept")
	request.setValue("application/json", forHTTPHeaderField: "Content-Type")
	request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
	let requestedMode = preferredBackendID.isEmpty ? "auto" : "backend(\(preferredBackendID))"
	print("Video CDN signed route request: origin=\(videoCDNOriginDescription(canonicalURL)), resource=\(resource), preference=\(requestedMode)")

	videoCDNRoutingSession().dataTask(with: request) { data, response, error in
		if let error {
			completion(.failure(.transport(error.localizedDescription)))
			return
		}
		guard let http = response as? HTTPURLResponse else {
			completion(.failure(.invalidResponse))
			return
		}
		guard http.statusCode == 201, let data else {
			let responseMessage = data.flatMap(videoCDNErrorMessage(from:)) ?? ""
			completion(.failure(.httpStatus(http.statusCode, responseMessage)))
			return
		}

		do {
			let route = try JSONDecoder().decode(VideoCDNRouteResponse.self, from: data)
			guard validateVideoCDNRoute(route, canonicalURL: canonicalURL) else {
				completion(.failure(.invalidPlaybackURL))
				return
			}
			completion(.success(route))
		} catch {
			completion(.failure(.transport("response decode failed: \(error.localizedDescription)")))
		}
	}.resume()
}

private func validateVideoCDNRoute(_ route: VideoCDNRouteResponse, canonicalURL: URL) -> Bool {
	guard let playbackURL = URL(string: route.playbackUrl),
		  let canonical = URLComponents(url: canonicalURL, resolvingAgainstBaseURL: false),
		  let playback = URLComponents(url: playbackURL, resolvingAgainstBaseURL: false),
		  canonical.scheme?.lowercased() == playback.scheme?.lowercased(),
		  canonical.host?.lowercased() == playback.host?.lowercased(),
		  canonical.port == playback.port,
		  canonical.percentEncodedPath == playback.percentEncodedPath else {
		return false
	}

	var tokenComponents = URLComponents()
	tokenComponents.queryItems = [URLQueryItem(name: videoCDNRouteQueryName, value: route.routeToken)]
	guard let encodedRouteQuery = tokenComponents.percentEncodedQuery else {
		return false
	}
	let expectedQuery = canonical.percentEncodedQuery.map { "\($0)&\(encodedRouteQuery)" } ?? encodedRouteQuery
	return playback.percentEncodedQuery == expectedQuery
}

private func logVideoCDNRoute(_ route: VideoCDNRouteResponse) {
	let backend = route.selectedBackend
	let region = backend.region?.isEmpty == false ? backend.region! : "unknown"
	let reason = route.selection.reason ?? "unknown"
	let expiry = route.expiresAt ?? "unknown"
	print(
		"Video CDN signed route selected: backendID=\(backend.id), " +
		"label=\(backend.label), region=\(region), availability=\(backend.availability), " +
		"mode=\(route.selection.mode), reason=\(reason), expiresAt=\(expiry)"
	)
}

private func canonicalVideoCDNURL(from string: String) -> URL? {
	guard let url = URL(string: string),
		  let scheme = url.scheme?.lowercased(),
		  scheme == "http" || scheme == "https",
		  url.host != nil,
		  var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
		return nil
	}
	components.fragment = nil
	if let queryItems = components.queryItems {
		let filtered = queryItems.filter { $0.name != videoCDNRouteQueryName }
		components.queryItems = filtered.isEmpty ? nil : filtered
	}
	return components.url
}

private func videoCDNRoutingEndpoint(path: String, for canonicalURL: URL) -> URL? {
	guard let source = URLComponents(url: canonicalURL, resolvingAgainstBaseURL: false) else {
		return nil
	}
	var endpoint = URLComponents()
	endpoint.scheme = source.scheme
	endpoint.host = source.host
	endpoint.port = source.port
	endpoint.percentEncodedPath = path
	return endpoint.url
}

private func videoCDNRoutingSession() -> URLSession {
	let configuration = URLSessionConfiguration.ephemeral
	configuration.httpShouldSetCookies = false
	configuration.httpCookieStorage = nil
	configuration.urlCache = nil
	configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
	return URLSession(configuration: configuration)
}

private func videoCDNURLContainsSignedRoute(_ url: URL) -> Bool {
	URLComponents(url: url, resolvingAgainstBaseURL: false)?
		.queryItems?
		.contains(where: { $0.name == videoCDNRouteQueryName }) == true
}

private func videoCDNOriginDescription(_ url: URL) -> String {
	guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
		  let scheme = components.scheme,
		  let host = components.host else {
		return "<invalid>"
	}
	return components.port.map { "\(scheme)://\(host):\($0)" } ?? "\(scheme)://\(host)"
}

private func videoCDNErrorMessage(from data: Data) -> String? {
	guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
		return nil
	}
	return object["error"] as? String
}
