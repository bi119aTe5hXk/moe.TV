//
//  AlbireoV2ServerHandler.swift
//  moe.TV
//
//  Handles Albireo V2 OAuth2 login and API v2 requests.
//

import CryptoKit
import Foundation

private let albireoV2SettingsHandler = SettingsHandler()
private let albireoV2Scopes = "openid offline_access profile bookmark"

private let albireoV2OAuthCodeLock = NSLock()
private var handledAlbireoV2OAuthCodes = Set<String>()
private var pendingAlbireoV2OAuthState: String?
private var pendingAlbireoV2OAuthCodeVerifier: String?

private func currentAlbireoV2ClientID() -> String {
	albireoV2SettingsHandler.registerSettings()
	let savedClientID = albireoV2SettingsHandler.getAlbireoV2ClientID().trimmingCharacters(in: .whitespacesAndNewlines)
	return savedClientID.isEmpty ? albireoV2ClientID : savedClientID
}

private func currentAlbireoV2RedirectHost() -> String {
	albireoV2SettingsHandler.registerSettings()
	let savedHost = albireoV2SettingsHandler.getAlbireoV2RedirectHost().trimmingCharacters(in: .whitespacesAndNewlines)
	return savedHost.isEmpty ? albireoV2RedirectHost : savedHost
}

private func currentAlbireoV2RedirectURI() -> String {
	"moetv://\(currentAlbireoV2RedirectHost())"
}

private func currentAlbireoV2AuthorizationServer() -> String {
	albireoV2SettingsHandler.registerSettings()
	return normalizedAlbireoV2ServerURL(
		albireoV2SettingsHandler.getAlbireoV2AuthorizationServerURL(),
		fallback: albireoV2DefaultAuthorizationServerURL
	)
}

private func currentAlbireoV2APIServer() -> String {
	albireoV2SettingsHandler.registerSettings()
	return normalizedAlbireoV2ServerURL(
		albireoV2SettingsHandler.getAlbireoV2APIServerURL(),
		fallback: albireoV2DefaultAPIServerURL
	)
}

private func currentAlbireoV2APIBaseURL() -> String {
	let server = currentAlbireoV2APIServer()
	if server.hasSuffix("/api/v2") {
		return server
	}
	return "\(server)/api/v2"
}

func isAlbireoV2Logined() -> Bool {
	albireoV2SettingsHandler.registerSettings()
	return !albireoV2SettingsHandler.getAlbireoV2AccessToken().isEmpty
}

func logoutAlbireoV2() {
	albireoV2SettingsHandler.clearAlbireoV2AuthInfo()
}

func startAlbireoV2Login(completion: @escaping (Bool, String) -> Void) {
	let clientID = currentAlbireoV2ClientID()
	guard !clientID.isEmpty else {
		completion(false, "Albireo V2 client id is empty.")
		return
	}
	guard !currentAlbireoV2RedirectHost().isEmpty else {
		completion(false, "Albireo V2 redirect host is empty.")
		return
	}

	let codeVerifier = makeAlbireoV2RandomString(length: 64)
	let codeChallenge = makeAlbireoV2CodeChallenge(verifier: codeVerifier)
	let state = makeAlbireoV2RandomString(length: 32)
	pendingAlbireoV2OAuthState = state
	pendingAlbireoV2OAuthCodeVerifier = codeVerifier

	let authorizationServer = currentAlbireoV2AuthorizationServer()
	let apiServer = currentAlbireoV2APIServer()
	var components = URLComponents(string: "\(authorizationServer)/oauth2/auth")
	components?.queryItems = [
		URLQueryItem(name: "client_id", value: clientID),
		URLQueryItem(name: "response_type", value: "code"),
		URLQueryItem(name: "redirect_uri", value: currentAlbireoV2RedirectURI()),
		URLQueryItem(name: "scope", value: albireoV2Scopes),
		URLQueryItem(name: "state", value: state),
		URLQueryItem(name: "audience", value: apiServer),
		URLQueryItem(name: "code_challenge", value: codeChallenge),
		URLQueryItem(name: "code_challenge_method", value: "S256")
	]

	guard let urlString = components?.url?.absoluteString else {
		completion(false, "Failed to build Albireo V2 OAuth URL.")
		return
	}

	#if os(tvOS)
	completion(false, "Albireo V2 OAuth login is not available on tvOS.")
	#else
	OAuthSessionManager.shared.start(urlString: urlString, callbackScheme: "moetv") { result in
		switch result {
		case .success(let callbackURL):
			print("Albireo V2 OAuth callback URL: \(callbackURL.absoluteString)")
			if !handleAlbireoV2OAuthCallback(callbackURL, completion: completion) {
				completion(false, "Albireo V2 OAuth callback missing code.")
			}
		case .failure(let error):
			completion(false, error.localizedDescription)
		}
	}
	#endif
}

@discardableResult
func handleAlbireoV2OAuthCallback(_ url: URL, completion: ((Bool, String) -> Void)? = nil) -> Bool {
	guard url.scheme == "moetv",
		  url.host == currentAlbireoV2RedirectHost(),
		  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
		  let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
		  !code.isEmpty else {
		return false
	}

	if let returnedState = components.queryItems?.first(where: { $0.name == "state" })?.value,
	   let expectedState = pendingAlbireoV2OAuthState,
	   returnedState != expectedState {
		completion?(false, "Albireo V2 OAuth state mismatch.")
		return true
	}

	albireoV2OAuthCodeLock.lock()
	let isNewCode = handledAlbireoV2OAuthCodes.insert(code).inserted
	albireoV2OAuthCodeLock.unlock()

	guard isNewCode else {
		print("Ignoring duplicate Albireo V2 OAuth code callback")
		completion?(true, "duplicate callback ignored")
		return true
	}

	guard let codeVerifier = pendingAlbireoV2OAuthCodeVerifier else {
		completion?(false, "Albireo V2 OAuth code verifier is missing.")
		return true
	}

	getAlbireoV2AccessToken(code: code, codeVerifier: codeVerifier) { isSuccess, result in
		if isSuccess {
			NotificationCenter.default.post(name: .getAlbireoV2UserInfo, object: nil)
		} else {
			print("getAlbireoV2AccessToken failed: \(result)")
		}
		completion?(isSuccess, result)
	}
	return true
}

func getAlbireoV2AccessToken(code: String, codeVerifier: String, completion: @escaping (Bool, String) -> Void) {
	let body = [
		"grant_type": "authorization_code",
		"client_id": currentAlbireoV2ClientID(),
		"code": code,
		"redirect_uri": currentAlbireoV2RedirectURI(),
		"code_verifier": codeVerifier
	]
	postAlbireoV2TokenRequest(body: body) { isSuccess, result in
		if isSuccess {
			pendingAlbireoV2OAuthState = nil
			pendingAlbireoV2OAuthCodeVerifier = nil
		}
		completion(isSuccess, result)
	}
}

func refreshAlbireoV2Token(completion: @escaping (Bool, String) -> Void) {
	let refreshToken = albireoV2SettingsHandler.getAlbireoV2RefreshToken()
	guard !refreshToken.isEmpty else {
		completion(false, "Albireo V2 refresh token is empty.")
		return
	}

	let body = [
		"grant_type": "refresh_token",
		"client_id": currentAlbireoV2ClientID(),
		"refresh_token": refreshToken
	]
	postAlbireoV2TokenRequest(body: body, completion: completion)
}

func ensureAlbireoV2AccessTokenValid(completion: @escaping (Bool, String) -> Void) {
	guard isAlbireoV2Logined() else {
		completion(false, "Albireo V2 access token is empty.")
		return
	}

	let expireTime = albireoV2SettingsHandler.getAlbireoV2ExpireTime()
	let now = Int(Date().timeIntervalSince1970)
	if expireTime > now + 120 {
		completion(true, "Albireo V2 access token is valid.")
		return
	}

	refreshAlbireoV2Token(completion: completion)
}

func getAlbireoV2UserInfo(completion: @escaping (Bool, Any) -> Void) {
	getAlbireoV2JSON(urlString: "\(currentAlbireoV2AuthorizationServer())/userinfo", completion: completion)
}

func getAlbireoV2AccountInfo(completion: @escaping (Bool, Any) -> Void) {
	getAlbireoV2JSON(urlString: "\(currentAlbireoV2APIBaseURL())/account/info", completion: completion)
}

func getAlbireoV2BangumiDetail(id: String, completion: @escaping (Bool, Any) -> Void) {
	var components = URLComponents(string: "\(currentAlbireoV2APIBaseURL())/bangumi/\(id)")
	components?.queryItems = [
		URLQueryItem(name: "loadEpisodes", value: "true"),
		URLQueryItem(name: "loadBangumiEpisodes", value: "true"),
		URLQueryItem(name: "loadFavorite", value: "true")
	]
	guard let urlString = components?.url?.absoluteString else {
		completion(false, "Failed to build Albireo V2 bangumi detail URL.")
		return
	}
	print("Albireo V2 bangumi detail request: \(urlString)")
	getAlbireoV2JSON(urlString: urlString) { result, data in
		if let responseData = data as? Data,
		   let responseText = String(data: responseData, encoding: .utf8) {
			print("Albireo V2 bangumi detail response: \(responseText)")
			print("Albireo V2 bangumi detail top-level keys: \(albireoV2TopLevelKeys(from: responseData))")
		} else {
			print("Albireo V2 bangumi detail response: \(data)")
		}
		completion(result, data)
	}
}

func getAlbireoV2EpisodeDetail(epID: String, defaultBangumiID: String? = nil, completion: @escaping (Bool, Any) -> Void) {
	var components = URLComponents(string: "\(currentAlbireoV2APIBaseURL())/episode/\(epID)")
	components?.queryItems = [
		URLQueryItem(name: "loadBangumiEpisodes", value: "true"),
		URLQueryItem(name: "loadFavorite", value: "true")
	]
	guard let urlString = components?.url?.absoluteString else {
		completion(false, "Failed to build Albireo V2 episode detail URL.")
		return
	}
	print("Albireo V2 episode detail request: \(urlString)")
	getAlbireoV2JSON(urlString: urlString) { result, data in
		if let responseData = data as? Data,
		   let responseText = String(data: responseData, encoding: .utf8) {
			print("Albireo V2 episode detail response: \(responseText)")
			if result {
				do {
					let episode = try decodeAlbireoV2EpisodeDetail(from: responseData, defaultBangumiId: defaultBangumiID ?? "")
					completion(true, episode)
				} catch {
					completion(false, "Albireo V2 episode detail decode failed: \(error.localizedDescription)")
				}
				return
			}
		} else {
			print("Albireo V2 episode detail response: \(data)")
		}
		completion(result, data)
	}
}

func getAlbireoV2FavoriteList(status: AlbireoV2FavoriteStatus,
						   offset: Int = 0,
						   limit: Int = -1,
						   completion: @escaping (Bool, Any) -> Void) {
	var components = URLComponents(string: "\(currentAlbireoV2APIBaseURL())/favorite")
	components?.queryItems = [
		URLQueryItem(name: "status", value: status.rawValue),
		URLQueryItem(name: "offset", value: String(offset)),
		URLQueryItem(name: "limit", value: String(limit)),
		URLQueryItem(name: "countUnwatched", value: "false"),
		URLQueryItem(name: "enableEpsUpdateTime", value: "false"),
		URLQueryItem(name: "orderBy", value: "updateTime"),
		URLQueryItem(name: "sort", value: "desc"),
		URLQueryItem(name: "coverImage", value: "false")
	]
	performAlbireoV2DebugListRequest(label: "favorite \(status.rawValue)", components: components, completion: completion)
}

func getAlbireoV2OnAirList(completion: @escaping (Bool, Any) -> Void) {
	var components = URLComponents(string: "\(currentAlbireoV2APIBaseURL())/bangumi/on-air")
	components?.queryItems = [
		URLQueryItem(name: "type", value: "anime")
	]
	performAlbireoV2DebugListRequest(label: "on-air", components: components, completion: completion)
}

func getAlbireoV2BangumiList(keyword: String = "",
						   offset: Int = 0,
						   limit: Int = 23,
						   completion: @escaping (Bool, Any) -> Void) {
	var components = URLComponents(string: "\(currentAlbireoV2APIBaseURL())/bangumi")
	var queryItems = [
		URLQueryItem(name: "offset", value: String(offset)),
		URLQueryItem(name: "limit", value: String(limit)),
		URLQueryItem(name: "orderBy", value: keyword.isEmpty ? "air_date" : "airDate"),
		URLQueryItem(name: "sort", value: "desc")
	]
	if keyword.isEmpty == false {
		queryItems.insert(URLQueryItem(name: "keyword", value: keyword), at: 0)
	}
	components?.queryItems = queryItems
	performAlbireoV2DebugListRequest(label: keyword.isEmpty ? "bangumi" : "search", components: components, completion: completion)
}

func changeAlbireoV2FavoriteStatus(bangumiID: String,
								   status: Int,
								   completion: @escaping (Bool, Any?) -> Void) {
	guard let favoriteStatus = AlbireoV2FavoriteStatus(legacyValue: status) else {
		completion(false, "Unsupported Albireo V2 favorite status: \(status)")
		return
	}

	let body: [String: Any] = [
		"bangumiId": bangumiID,
		"status": favoriteStatus.rawValue,
		"review": "",
		"syncToUpstream": true
	]
	postAlbireoV2JSON(urlString: "\(currentAlbireoV2APIBaseURL())/favorite", body: body, completion: completion)
}

func syncAlbireoV2EpisodeWatchProgress(epID: String,
									   bangumiID: String,
									   lastWatchPosition: Double,
									   percentage: Double,
									   isFinished: Bool,
									   completion: @escaping (Bool, Any?) -> Void) {
	let record: [String: Any] = [
		"bangumiId": bangumiID,
		"episodeId": epID,
		"lastWatchPosition": lastWatchPosition,
		"lastWatchTime": albireoV2CurrentISOString(),
		"isFinished": isFinished,
		"percentage": percentage,
		"version": 2
	]
	let body: [String: Any] = [
		"records": [record]
	]
	postAlbireoV2JSON(urlString: "\(currentAlbireoV2APIBaseURL())/episode/watch/sync", body: body, completion: completion)
}

private func performAlbireoV2DebugListRequest(label: String,
										components: URLComponents?,
										completion: @escaping (Bool, Any) -> Void) {
	guard let urlString = components?.url?.absoluteString else {
		completion(false, "Failed to build Albireo V2 \(label) URL.")
		return
	}
	print("Albireo V2 \(label) request: \(urlString)")
	getAlbireoV2JSON(urlString: urlString) { result, data in
		if let responseData = data as? Data,
		   let responseText = String(data: responseData, encoding: .utf8) {
			print("Albireo V2 \(label) response: \(responseText)")
		} else {
			print("Albireo V2 \(label) response: \(data)")
		}
		completion(result, data)
	}
}

private func postAlbireoV2JSON(urlString: String,
							   body: [String: Any],
							   completion: @escaping (Bool, Any?) -> Void) {
	ensureAlbireoV2AccessTokenValid { isTokenReady, tokenResult in
		guard isTokenReady else {
			completion(false, tokenResult)
			return
		}

		guard let url = URL(string: urlString) else {
			completion(false, "Invalid Albireo V2 URL: \(urlString)")
			return
		}

		do {
			var request = URLRequest(url: url)
			request.httpMethod = "POST"
			request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
			request.setValue("en-US,en;q=0.9,ja-JP;q=0.8,ja;q=0.7,zh-CN;q=0.6,zh;q=0.5", forHTTPHeaderField: "Accept-Language")
			request.setValue(currentAlbireoV2APIServer(), forHTTPHeaderField: "Origin")
			request.setValue(currentAlbireoV2APIServer(), forHTTPHeaderField: "Referer")
			request.setValue("Bearer \(albireoV2SettingsHandler.getAlbireoV2AccessToken())", forHTTPHeaderField: "Authorization")
			request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

			print("Albireo V2 POST request: \(urlString), body: \(body)")
			URLSession.shared.dataTask(with: request) { data, response, error in
				if let error {
					completion(false, error.localizedDescription)
					return
				}

				if let httpResponse = response as? HTTPURLResponse,
				   httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
					let responseText = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
					completion(false, "Albireo V2 API HTTP \(httpResponse.statusCode): \(responseText)")
					return
				}

				if let data,
				   let responseText = String(data: data, encoding: .utf8) {
					completion(true, responseText)
				} else {
					completion(true, "success")
				}
			}.resume()
		} catch {
			completion(false, "Cannot convert Albireo V2 JSON body: \(error.localizedDescription)")
		}
	}
}

private func albireoV2CurrentISOString() -> String {
	let formatter = ISO8601DateFormatter()
	formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
	formatter.timeZone = TimeZone(secondsFromGMT: 0)
	return formatter.string(from: Date())
}

private func postAlbireoV2TokenRequest(body: [String: String], completion: @escaping (Bool, String) -> Void) {
	guard let url = URL(string: "\(currentAlbireoV2AuthorizationServer())/oauth2/token") else {
		completion(false, "Invalid Albireo V2 token endpoint.")
		return
	}

	var request = URLRequest(url: url)
	request.httpMethod = "POST"
	request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
	request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
	request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
	request.httpBody = formURLEncodedData(body)

	URLSession.shared.dataTask(with: request) { data, response, error in
		if let error {
			completion(false, error.localizedDescription)
			return
		}

		if let httpResponse = response as? HTTPURLResponse,
		   httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
			let responseText = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
			completion(false, "Albireo V2 token HTTP \(httpResponse.statusCode): \(responseText)")
			return
		}

		guard let data else {
			completion(false, "Albireo V2 token response is empty.")
			return
		}

		do {
			let token = try JSONDecoder().decode(AlbireoV2OAuthTokenResponse.self, from: data)
			saveAlbireoV2Token(token)
			completion(true, "Albireo V2 OAuth token saved.")
		} catch {
			let responseText = String(data: data, encoding: .utf8) ?? ""
			completion(false, "Albireo V2 token decode error: \(error.localizedDescription), response: \(responseText)")
		}
	}.resume()
}

private func getAlbireoV2JSON(urlString: String, completion: @escaping (Bool, Any) -> Void) {
	ensureAlbireoV2AccessTokenValid { isTokenReady, tokenResult in
		guard isTokenReady else {
			completion(false, tokenResult)
			return
		}

		guard let url = URL(string: urlString) else {
			completion(false, "Invalid Albireo V2 URL: \(urlString)")
			return
		}

		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
		request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
		request.setValue("en-US,en;q=0.9,ja-JP;q=0.8,ja;q=0.7,zh-CN;q=0.6,zh;q=0.5", forHTTPHeaderField: "Accept-Language")
		request.setValue(currentAlbireoV2APIServer(), forHTTPHeaderField: "Origin")
		request.setValue(currentAlbireoV2APIServer(), forHTTPHeaderField: "Referer")
		request.setValue("Bearer \(albireoV2SettingsHandler.getAlbireoV2AccessToken())", forHTTPHeaderField: "Authorization")

		URLSession.shared.dataTask(with: request) { data, response, error in
			if let error {
				completion(false, error.localizedDescription)
				return
			}

			if let httpResponse = response as? HTTPURLResponse,
			   httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
				let responseText = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
				if httpResponse.statusCode == 401 {
					printAlbireoV2AccessTokenPayload(label: "Albireo V2 current access token payload after 401", accessToken: albireoV2SettingsHandler.getAlbireoV2AccessToken())
				}
				completion(false, "Albireo V2 API HTTP \(httpResponse.statusCode): \(responseText)")
				return
			}

			guard let data else {
				completion(false, "Albireo V2 API response is empty.")
				return
			}
			completion(true, data)
		}.resume()
	}
}

private func saveAlbireoV2Token(_ token: AlbireoV2OAuthTokenResponse) {
	printAlbireoV2TokenDebugInfo(token)
	albireoV2SettingsHandler.setAlbireoV2AccessToken(token.accessToken)
	if let refreshToken = token.refreshToken, !refreshToken.isEmpty {
		albireoV2SettingsHandler.setAlbireoV2RefreshToken(refreshToken)
	}
	if let idToken = token.idToken {
		albireoV2SettingsHandler.setAlbireoV2IDToken(idToken)
	}
	let expireIn = token.expiresIn ?? 3600
	let expireTime = Int(Date().timeIntervalSince1970) + expireIn
	albireoV2SettingsHandler.setAlbireoV2ExpireTime(expireTime)
	albireoV2SettingsHandler.setAlbireoAuthMode(.albireoV2OAuth)
}

private func printAlbireoV2TokenDebugInfo(_ token: AlbireoV2OAuthTokenResponse) {
	print("Albireo V2 token scope: \(token.scope ?? "nil")")
	printAlbireoV2AccessTokenPayload(label: "Albireo V2 access token payload", accessToken: token.accessToken)
}

private func printAlbireoV2AccessTokenPayload(label: String, accessToken: String) {
	let parts = accessToken.split(separator: ".")
	guard parts.count >= 2,
		  let payloadData = Data(base64URLString: String(parts[1])),
		  let payload = try? JSONSerialization.jsonObject(with: payloadData) else {
		print("\(label) is not a readable JWT payload")
		return
	}
	print("\(label): \(payload)")
}

private func makeAlbireoV2RandomString(length: Int) -> String {
	let allowed = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
	return String((0..<length).compactMap { _ in allowed.randomElement() })
}

private func makeAlbireoV2CodeChallenge(verifier: String) -> String {
	let digest = SHA256.hash(data: Data(verifier.utf8))
	return Data(digest).base64URLEncodedString()
}

private func normalizedAlbireoV2ServerURL(_ rawValue: String, fallback: String) -> String {
	normalizedServerURL(rawValue, fallback: fallback)
}
