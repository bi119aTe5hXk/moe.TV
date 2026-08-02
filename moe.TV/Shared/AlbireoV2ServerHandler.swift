//
//  AlbireoV2ServerHandler.swift
//  moe.TV
//
//  Handles Albireo V2 OAuth2 login and API v2 requests.
//

import CryptoKit
import Foundation
import MiraStreamingSDK

private let albireoV2SettingsHandler = SettingsHandler()
private let albireoV2Scopes = "openid offline_access profile bookmark"
private let albireoV2OIDCIssuerURL = "https://authorization.box.moe"
private let albireoV2RedirectHost = "box.moe"

private let albireoV2OAuthCodeLock = NSLock()
private var handledAlbireoV2OAuthCodes = Set<String>()
private var pendingAlbireoV2OAuthState: String?
private var pendingAlbireoV2OAuthCodeVerifier: String?
private var cachedAlbireoV2OIDCConfiguration: AlbireoV2OIDCConfiguration?

private struct AlbireoV2OIDCConfiguration: Decodable {
	let issuer: String
	let authorizationEndpoint: String
	let tokenEndpoint: String
	let userinfoEndpoint: String
	let jwksURI: String
	let endSessionEndpoint: String?

	enum CodingKeys: String, CodingKey {
		case issuer
		case authorizationEndpoint = "authorization_endpoint"
		case tokenEndpoint = "token_endpoint"
		case userinfoEndpoint = "userinfo_endpoint"
		case jwksURI = "jwks_uri"
		case endSessionEndpoint = "end_session_endpoint"
	}
}

private func currentAlbireoV2ClientID() -> String {
	albireoV2ClientID.trimmingCharacters(in: .whitespacesAndNewlines)
}

private func currentAlbireoV2RedirectURI() -> String {
	"moetv://\(albireoV2RedirectHost)"
}

private func currentAlbireoV2AuthorizationServer() -> String {
	albireoV2OIDCIssuerURL
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
	albireoV2SettingsHandler.registerSettings()
	let idToken = albireoV2SettingsHandler.getAlbireoV2IDToken()
	albireoV2SettingsHandler.clearAlbireoV2AuthInfo()

	#if !os(tvOS)
	guard !idToken.isEmpty else {
		return
	}

	loadAlbireoV2OIDCConfiguration { result in
		switch result {
		case .success(let oidcConfiguration):
			guard let endSessionEndpoint = oidcConfiguration.endSessionEndpoint,
				  var components = URLComponents(string: endSessionEndpoint) else {
				return
			}
			components.queryItems = [
				URLQueryItem(name: "id_token_hint", value: idToken),
				URLQueryItem(name: "post_logout_redirect_uri", value: currentAlbireoV2RedirectURI())
			]

			guard let urlString = components.url?.absoluteString else {
				return
			}
			OAuthSessionManager.shared.start(urlString: urlString, callbackScheme: "moetv") { result in
				switch result {
				case .success:
					print("Albireo V2 provider logout completed.")
				case .failure(let error):
					print("Albireo V2 provider logout failed or canceled: \(error.localizedDescription)")
				}
			}
		case .failure(let error):
			print("Albireo V2 provider logout skipped: \(error.localizedDescription)")
		}
	}
	#endif
}

func startAlbireoV2Login(completion: @escaping (Bool, String) -> Void) {
	let clientID = currentAlbireoV2ClientID()
	guard !clientID.isEmpty else {
		completion(false, "Albireo V2 client id is empty.")
		return
	}

	let codeVerifier = makeAlbireoV2RandomString(length: 64)
	let codeChallenge = makeAlbireoV2CodeChallenge(verifier: codeVerifier)
	let state = makeAlbireoV2RandomString(length: 32)
	pendingAlbireoV2OAuthState = state
	pendingAlbireoV2OAuthCodeVerifier = codeVerifier

	loadAlbireoV2OIDCConfiguration { result in
		switch result {
		case .success(let oidcConfiguration):
			let apiServer = currentAlbireoV2APIServer()
			var components = URLComponents(string: oidcConfiguration.authorizationEndpoint)
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
		case .failure(let error):
			completion(false, error.localizedDescription)
		}
	}
}

@discardableResult
func handleAlbireoV2OAuthCallback(_ url: URL, completion: ((Bool, String) -> Void)? = nil) -> Bool {
	guard url.scheme == "moetv",
		  url.host == albireoV2RedirectHost,
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
	loadAlbireoV2OIDCConfiguration { result in
		switch result {
		case .success(let oidcConfiguration):
			getAlbireoV2OIDCJSON(urlString: oidcConfiguration.userinfoEndpoint, completion: completion)
		case .failure(let error):
			completion(false, error.localizedDescription)
		}
	}
}

func getAlbireoV2AccountInfo(completion: @escaping (Bool, Any) -> Void) {
	performAlbireoV2SDKRequest(
		label: "account info",
		operation: { configuration in
			try await AccountAPI(apiConfiguration: configuration).getAccountInfo()
		},
		completion: completion
	)
}

func getAlbireoV2BangumiDetail(id: String, completion: @escaping (Bool, Any) -> Void) {
	guard let bangumiID = UUID(uuidString: id) else {
		completion(false, "Invalid Albireo V2 bangumi id: \(id)")
		return
	}

	performAlbireoV2SDKRequest(
		label: "bangumi detail \(id)",
		operation: { configuration in
			let detail = try await BangumiAPI(apiConfiguration: configuration).getBangumi(id: bangumiID)
			return detail.toBangumiDetailModel()
		},
		completion: completion
	)
}

func getAlbireoV2EpisodeDetail(epID: String, defaultBangumiID: String? = nil, completion: @escaping (Bool, Any) -> Void) {
	guard let episodeID = UUID(uuidString: epID) else {
		completion(false, "Invalid Albireo V2 episode id: \(epID)")
		return
	}

	performAlbireoV2SDKRequest(
		label: "episode detail \(epID)",
		operation: { configuration in
			let detail = try await EpisodeAPI(apiConfiguration: configuration).getEpisode(
				id: episodeID,
				loadBangumiEpisodes: true,
				loadFavorite: true
			)
			return detail.toEpisodeDetailModel()
		},
		completion: completion
	)
}

func getAlbireoV2FavoriteList(status: FavoriteStatus,
						   offset: Int = 0,
						   limit: Int = -1,
						   completion: @escaping (Bool, Any) -> Void) {
	performAlbireoV2SDKRequest(
		label: "favorite \(status.rawValue)",
		operation: { configuration in
			let response = try await FavoriteAPI(apiConfiguration: configuration).listFavorites(
				status: status,
				enableEpsUpdateTime: false,
				countUnwatched: true,
				coverImage: false,
				offset: offset,
				limit: limit,
				orderBy: .updatetime,
				sort: .desc
			)
			return response.toBangumiItemModels()
		},
		completion: completion
	)
}

func getAlbireoV2OnAirList(completion: @escaping (Bool, Any) -> Void) {
	performAlbireoV2SDKRequest(
		label: "on-air",
		operation: { configuration in
			let response = try await BangumiAPI(apiConfiguration: configuration).listOnAirBangumi(type: .anime)
			return response.toBangumiItemModels()
		},
		completion: completion
	)
}

func getAlbireoV2BangumiList(keyword: String = "",
						   offset: Int = 0,
						   limit: Int = 23,
						   completion: @escaping (Bool, Any) -> Void) {
	performAlbireoV2SDKRequest(
		label: keyword.isEmpty ? "bangumi" : "search",
		operation: { configuration in
			let response = try await BangumiAPI(apiConfiguration: configuration).listBangumi(
				offset: offset,
				limit: limit,
				orderBy: .airdate,
				sort: .desc,
				keyword: keyword.isEmpty ? nil : keyword
			)
			return response.toBangumiItemModels()
		},
		completion: completion
	)
}

func changeAlbireoV2FavoriteStatus(bangumiID: String,
								   status: Int,
								   completion: @escaping (Bool, Any?) -> Void) {
	guard let favoriteStatus = FavoriteStatus(legacyValue: status),
		  let bangumiUUID = UUID(uuidString: bangumiID) else {
		completion(false, "Unsupported Albireo V2 favorite status: \(status)")
		return
	}

	performAlbireoV2SDKRequest(
		label: "change favorite status",
		operation: { configuration in
			try await FavoriteAPI(apiConfiguration: configuration).createOrUpdateFavorite(
				favoriteCreateRequest: FavoriteCreateRequest(
					status: favoriteStatus,
					bangumiId: bangumiUUID,
					review: "",
					syncToUpstream: true
				)
			)
		},
		completion: { success, result in
			completion(success, result)
		}
	)
}

func syncAlbireoV2EpisodeWatchProgress(epID: String,
									   bangumiID: String,
									   lastWatchPosition: Double,
									   percentage: Double,
									   isFinished: Bool,
									   completion: @escaping (Bool, Any?) -> Void) {
	guard let episodeUUID = UUID(uuidString: epID),
		  let bangumiUUID = UUID(uuidString: bangumiID) else {
		completion(false, "Invalid Albireo V2 episode or bangumi id.")
		return
	}

	let record = WatchHistoryRecord(
		bangumiId: bangumiUUID,
		episodeId: episodeUUID,
		lastWatchPosition: lastWatchPosition,
		lastWatchTime: Date(),
		percentage: percentage,
		isFinished: isFinished
	)
	performAlbireoV2SDKRequest(
		label: "sync watch progress",
		operation: { configuration in
			try await EpisodeAPI(apiConfiguration: configuration).syncWatchProgress(
				batchWatchProgressRequest: BatchWatchProgressRequest(records: [record]),
				syncToUpstream: true
			)
		},
		completion: { success, result in
			completion(success, result)
		}
	)
}

private func performAlbireoV2SDKRequest<T: Sendable>(
	label: String,
	operation: @escaping @Sendable (MiraStreamingSDKAPIConfiguration) async throws -> T,
	completion: @escaping (Bool, Any) -> Void
) {
	ensureAlbireoV2AccessTokenValid { isTokenReady, tokenResult in
		guard isTokenReady else {
			completion(false, tokenResult)
			return
		}

		print("Albireo V2 SDK request: \(label)")
		Task {
			do {
				let result = try await operation(makeAlbireoV2SDKConfiguration())
				print("Albireo V2 SDK response: \(label) succeeded")
				completion(true, result)
			} catch {
				let message = albireoV2SDKErrorMessage(error)
				print("Albireo V2 SDK response: \(label) failed: \(message)")
				completion(false, message)
			}
		}
	}
}

private func makeAlbireoV2SDKConfiguration() -> MiraStreamingSDKAPIConfiguration {
	let apiServer = currentAlbireoV2APIServer()
	return MiraStreamingSDKAPIConfiguration(
		basePath: currentAlbireoV2APIBaseURL(),
		customHeaders: [
			"Accept": "application/json, text/plain, */*",
			"Accept-Language": "en-US,en;q=0.9,ja-JP;q=0.8,ja;q=0.7,zh-CN;q=0.6,zh;q=0.5",
			"Authorization": "Bearer \(albireoV2SettingsHandler.getAlbireoV2AccessToken())",
			"Origin": apiServer,
			"Referer": apiServer,
			"User-Agent": AppConstants.userAgent
		],
		codableHelper: makeAlbireoV2CodableHelper()
	)
}

private func makeAlbireoV2CodableHelper() -> CodableHelper {
	let helper = CodableHelper()
	let decoder = JSONDecoder()
	decoder.dateDecodingStrategy = .custom { decoder in
		let container = try decoder.singleValueContainer()
		let value = try container.decode(String.self)
		guard let date = decodeAlbireoV2Date(value) else {
			throw DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "Unsupported Albireo V2 date: \(value)"
			)
		}
		return date
	}
	helper.jsonDecoder = decoder
	return helper
}

private func decodeAlbireoV2Date(_ value: String) -> Date? {
	let iso8601WithFractionalSeconds = ISO8601DateFormatter()
	iso8601WithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
	if let date = iso8601WithFractionalSeconds.date(from: value) {
		return date
	}

	let iso8601 = ISO8601DateFormatter()
	if let date = iso8601.date(from: value) {
		return date
	}

	let formatter = DateFormatter()
	formatter.calendar = Calendar(identifier: .iso8601)
	formatter.locale = Locale(identifier: "en_US_POSIX")
	formatter.timeZone = TimeZone(secondsFromGMT: 0)
	for format in ["yyyy-MM-dd HH:mm:ss.SSS", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"] {
		formatter.dateFormat = format
		if let date = formatter.date(from: value) {
			return date
		}
	}
	return nil
}

private func albireoV2SDKErrorMessage(_ error: Error) -> String {
	guard case let ErrorResponse.error(statusCode, data, _, underlyingError) = error else {
		return error.localizedDescription
	}
	if statusCode == 401 {
		printAlbireoV2AccessTokenPayload(
			label: "Albireo V2 current access token payload after 401",
			accessToken: albireoV2SettingsHandler.getAlbireoV2AccessToken()
		)
	}
	let responseText = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
	return "Albireo V2 API HTTP \(statusCode): \(responseText.isEmpty ? underlyingError.localizedDescription : responseText)"
}

private func postAlbireoV2TokenRequest(body: [String: String], completion: @escaping (Bool, String) -> Void) {
	loadAlbireoV2OIDCConfiguration { result in
		switch result {
		case .success(let oidcConfiguration):
			guard let url = URL(string: oidcConfiguration.tokenEndpoint) else {
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
		case .failure(let error):
			completion(false, error.localizedDescription)
		}
	}
}

private func loadAlbireoV2OIDCConfiguration(completion: @escaping (Result<AlbireoV2OIDCConfiguration, Error>) -> Void) {
	if let cachedAlbireoV2OIDCConfiguration {
		completion(.success(cachedAlbireoV2OIDCConfiguration))
		return
	}

	guard let url = URL(string: "\(albireoV2OIDCIssuerURL)/.well-known/openid-configuration") else {
		completion(.failure(NSError(domain: "moe.TV.AlbireoV2OIDC", code: -1, userInfo: [
			NSLocalizedDescriptionKey: "Invalid Albireo V2 OIDC discovery URL."
		])))
		return
	}

	var request = URLRequest(url: url)
	request.httpMethod = "GET"
	request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
	request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")

	URLSession.shared.dataTask(with: request) { data, response, error in
		if let error {
			completion(.failure(error))
			return
		}

		if let httpResponse = response as? HTTPURLResponse,
		   httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
			let responseText = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
			completion(.failure(NSError(domain: "moe.TV.AlbireoV2OIDC", code: httpResponse.statusCode, userInfo: [
				NSLocalizedDescriptionKey: "Albireo V2 OIDC discovery HTTP \(httpResponse.statusCode): \(responseText)"
			])))
			return
		}

		guard let data else {
			completion(.failure(NSError(domain: "moe.TV.AlbireoV2OIDC", code: -2, userInfo: [
				NSLocalizedDescriptionKey: "Albireo V2 OIDC discovery response is empty."
			])))
			return
		}

		do {
			let configuration = try JSONDecoder().decode(AlbireoV2OIDCConfiguration.self, from: data)
			guard configuration.issuer == albireoV2OIDCIssuerURL else {
				completion(.failure(NSError(domain: "moe.TV.AlbireoV2OIDC", code: -3, userInfo: [
					NSLocalizedDescriptionKey: "Albireo V2 OIDC issuer mismatch."
				])))
				return
			}
			cachedAlbireoV2OIDCConfiguration = configuration
			completion(.success(configuration))
		} catch {
			completion(.failure(error))
		}
	}.resume()
}

private func getAlbireoV2OIDCJSON(urlString: String, completion: @escaping (Bool, Any) -> Void) {
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
