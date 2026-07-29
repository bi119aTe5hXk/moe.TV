//
//  AlbireoV1ServerHandler.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2019/08/15.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//  Handles legacy Albireo V1 cookie login and API requests.
//
import Foundation

private var serverAddr = ""
private let settingsHandler:SettingsHandler = SettingsHandler()
private let jsonDecoder = JSONDecoder()
private let albireoCookieQueue = DispatchQueue(label: "net.bi119aTe5hXk.moetv.albireo-v1-cookies")
private let albireoV1RequestQueue = AlbireoV1RequestQueue()

private final class AlbireoV1RequestQueue {
	typealias Operation = (@escaping () -> Void) -> Void

	private let stateQueue = DispatchQueue(label: "net.bi119aTe5hXk.moetv.albireo-v1-requests")
	private var pendingOperations: [Operation] = []
	private var isRunning = false

	func enqueue(_ operation: @escaping Operation) {
		stateQueue.async {
			self.pendingOperations.append(operation)
			self.startNextIfNeeded()
		}
	}

	private func startNextIfNeeded() {
		guard !isRunning, !pendingOperations.isEmpty else { return }
		isRunning = true
		let operation = pendingOperations.removeFirst()
		operation { [weak self] in
			self?.stateQueue.async {
				guard let self else { return }
				self.isRunning = false
				self.startNextIfNeeded()
			}
		}
	}
}

private struct AlbireoCookieKey: Hashable {
	let name: String
	let domain: String
	let path: String

	init(_ cookie: HTTPCookie) {
		name = cookie.name
		domain = cookie.domain.lowercased()
		path = cookie.path
	}
}

private func isAlbireoAPICookie(_ cookie: HTTPCookie) -> Bool {
	// The video CDN selector uses a host-wide cookie named "group". It must
	// never be persisted or sent as part of the legacy API authentication.
	cookie.name.caseInsensitiveCompare("group") != .orderedSame
}

private func storedAlbireoCookies() -> [HTTPCookie] {
	guard let cookieArray = settingsHandler.getAlbireoCookie() else { return [] }
	return cookieArray.compactMap { item in
		guard let properties = item as? [HTTPCookiePropertyKey: Any] else { return nil }
		return HTTPCookie(properties: properties)
	}.filter(isAlbireoAPICookie)
}

private func isCookie(_ cookie: HTTPCookie, forHost host: String) -> Bool {
	let normalizedDomain = cookie.domain.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
	let normalizedHost = host.lowercased()
	return normalizedHost == normalizedDomain || normalizedHost.hasSuffix(".\(normalizedDomain)")
}

private func albireoServerHost() -> String? {
	URL(string: settingsHandler.getAlbireoServerAddr())?.host
}

private func cookieFingerprint(_ cookies: [HTTPCookie]) -> String {
	cookies
		.sorted { AlbireoCookieKey($0).name < AlbireoCookieKey($1).name }
		.map { cookie in
			let valueFingerprint = String(cookie.value.hashValue, radix: 16)
			return "\(cookie.name)=\(valueFingerprint)"
		}
		.joined(separator: ",")
}

private func cookieFingerprint(for url: URL) -> String {
	cookieFingerprint(albireoAPICookies(for: url))
}

private func albireoAPICookies(for url: URL) -> [HTTPCookie] {
	(HTTPCookieStorage.shared.cookies(for: url) ?? []).filter(isAlbireoAPICookie)
}

private func applyAlbireoCookies(to request: inout URLRequest, for url: URL) {
	let cookies = albireoAPICookies(for: url)
	let headerFields = HTTPCookie.requestHeaderFields(with: cookies)
	for (field, value) in headerFields {
		request.setValue(value, forHTTPHeaderField: field)
	}
	// Cookie persistence is handled below after validating the HTTP response.
	request.httpShouldHandleCookies = false
}

private func albireoErrorMessage(statusCode: Int, data: Data?) -> String {
	guard let data, let body = String(data: data, encoding: .utf8), !body.isEmpty else {
		return "Server HTTP status code \(statusCode) error."
	}
	let limitedBody = String(body.prefix(2_000))
	return "Server HTTP status code \(statusCode) error: \(limitedBody)"
}

func saveAlbireoCookies(response: HTTPURLResponse) {
	guard let responseURL = response.url, let host = responseURL.host else { return }
	let headerFields = response.allHeaderFields.reduce(into: [String: String]()) { fields, entry in
		fields[String(describing: entry.key)] = String(describing: entry.value)
	}
	let responseCookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: responseURL)
	guard !responseCookies.isEmpty else { return }

	albireoCookieQueue.sync {
		var merged: [AlbireoCookieKey: HTTPCookie] = [:]
		for cookie in storedAlbireoCookies() where isCookie(cookie, forHost: host) {
			merged[AlbireoCookieKey(cookie)] = cookie
		}

		for cookie in HTTPCookieStorage.shared.cookies ?? []
			where isCookie(cookie, forHost: host) && isAlbireoAPICookie(cookie) {
			merged[AlbireoCookieKey(cookie)] = cookie
		}

		for cookie in responseCookies where isAlbireoAPICookie(cookie) {
			let key = AlbireoCookieKey(cookie)
			if let expiresDate = cookie.expiresDate, expiresDate <= Date() {
				merged.removeValue(forKey: key)
				HTTPCookieStorage.shared.deleteCookie(cookie)
			} else {
				merged[key] = cookie
				HTTPCookieStorage.shared.setCookie(cookie)
			}
		}

		let cookies = Array(merged.values)
		let properties = cookies.compactMap(\.properties)
		settingsHandler.setAlbireoCookie(array: properties)
		print("Albireo V1 cookies updated: names=\(cookies.map(\.name).sorted()), fingerprint=\(cookieFingerprint(cookies))")
	}
}

//return true if have cookie result
func loadAlbireoCookies() -> Bool {
	settingsHandler.registerSettings()
	guard let host = albireoServerHost() else { return false }

	return albireoCookieQueue.sync {
		let currentCookies = (HTTPCookieStorage.shared.cookies ?? []).filter {
			isCookie($0, forHost: host)
				&& isAlbireoAPICookie($0)
				&& ($0.expiresDate == nil || $0.expiresDate! > Date())
		}
		var currentKeys = Set(currentCookies.map(AlbireoCookieKey.init))
		var availableCookies = currentCookies

		for cookie in storedAlbireoCookies() where isCookie(cookie, forHost: host) {
			guard cookie.expiresDate == nil || cookie.expiresDate! > Date() else { continue }
			let key = AlbireoCookieKey(cookie)
			// Never overwrite a newer in-memory session with a stale iCloud copy.
			guard !currentKeys.contains(key) else { continue }
			HTTPCookieStorage.shared.setCookie(cookie)
			currentKeys.insert(key)
			availableCookies.append(cookie)
		}

		if !availableCookies.isEmpty {
			print("Albireo V1 cookies loaded: names=\(availableCookies.map(\.name).sorted()), fingerprint=\(cookieFingerprint(availableCookies))")
			return true
		}
		return false
	}
}
func getAllCookies(completion: @escaping (Array<String>) -> Void){
	    if let cookieArray = settingsHandler.getAlbireoCookie(){
	        var newArr:Array<String> = []
	        for cookieProperties in cookieArray {
	            if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any]),
				   isAlbireoAPICookie(cookie) {
                print("\(cookie)")
                newArr.append("\(cookie)")
            }
        }
        
        completion(newArr)
    }
}
func clearCookie(){
	albireoCookieQueue.sync {
		settingsHandler.setAlbireoCookie(array: [])
		if let host = albireoServerHost() {
			HTTPCookieStorage.shared.cookies?
				.filter { isCookie($0, forHost: host) }
				.forEach(HTTPCookieStorage.shared.deleteCookie)
		}
	}
	print("Albireo V1 cookies cleared")
}

func isAlbireoAuthenticated() -> Bool {
	settingsHandler.registerSettings()
	switch settingsHandler.getAlbireoAuthMode() {
	case .albireoV2OAuth:
		return isAlbireoV2Logined()
	case .legacyCookie:
		return loadAlbireoCookies()
	}
}

func isAlbireoLoginValid(completion: @escaping (Bool) -> Void){
	settingsHandler.registerSettings()
	switch settingsHandler.getAlbireoAuthMode() {
	case .albireoV2OAuth:
		getAlbireoV2UserInfo { result, _ in
			completion(result)
		}
	case .legacyCookie:
		getAlbireoUserInfo { result, data in
			completion(result)
		}
	}
}


func getAlbireoServer() -> String?{
    serverAddr = settingsHandler.getAlbireoServerAddr()
    return serverAddr
}
func fixPathNotCompete(path:String) -> String{
	completeServerPath(baseURL: settingsHandler.getAlbireoServerAddr(), path: path)
}

private func postServer(urlString:String,
                postdata:Dictionary<String,Any>,
                completion: @escaping (Bool, Any) -> Void) {
	do {
		guard let url = URL(string: urlString) else {
			completion(false, "Invalid server URL.")
			return
		}
		let body = try JSONSerialization.data(withJSONObject: postdata, options: .prettyPrinted)

		albireoV1RequestQueue.enqueue { finish in
			var request = URLRequest(url: url)
			request.httpMethod = "POST"
			request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
			request.httpBody = body
			request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
			applyAlbireoCookies(to: &request, for: url)
			let requestID = String(UUID().uuidString.prefix(8))
			print("Albireo V1 POST [\(requestID)] \(url.path), cookieHeader=\(request.value(forHTTPHeaderField: "Cookie") != nil), cookies=\(cookieFingerprint(for: url))")

			URLSession.shared.dataTask(with: request) { data, response, error in
				if let error {
					print("Albireo V1 POST [\(requestID)] transport error: \(error.localizedDescription)")
					completion(false, error.localizedDescription)
					finish()
					return
				}

				if let response = response as? HTTPURLResponse {
					print("Albireo V1 POST [\(requestID)] status=\(response.statusCode)")
					if response.statusCode < 200 || response.statusCode >= 300 {
						let message = albireoErrorMessage(statusCode: response.statusCode, data: data)
						print("Albireo V1 POST [\(requestID)] response: \(message)")
						completion(false, message)
						finish()
						return
					}
					saveAlbireoCookies(response: response)
				}

				guard let data else {
					completion(false, "Server returned no data.")
					finish()
					return
				}
				completion(true, data)
				finish()
			}.resume()
		}
	} catch {
		completion(false, "Cannot convert postdata to json")
	}
}

private func getServer(urlString:String,
               completion: @escaping (Bool, Any) -> Void) {
	guard let url = URL(string: urlString) else {
		completion(false, "Invalid server URL.")
		return
	}

	albireoV1RequestQueue.enqueue { finish in
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
		request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
		applyAlbireoCookies(to: &request, for: url)
		let requestID = String(UUID().uuidString.prefix(8))
		print("Albireo V1 GET [\(requestID)] \(url.path), cookieHeader=\(request.value(forHTTPHeaderField: "Cookie") != nil), cookies=\(cookieFingerprint(for: url))")

		URLSession.shared.dataTask(with: request) { data, response, error in
			if let error {
				print("Albireo V1 GET [\(requestID)] transport error: \(error.localizedDescription)")
				completion(false, error.localizedDescription)
				finish()
				return
			}

			if let response = response as? HTTPURLResponse {
				print("Albireo V1 GET [\(requestID)] status=\(response.statusCode)")
				if response.statusCode < 200 || response.statusCode >= 300 {
					let message = albireoErrorMessage(statusCode: response.statusCode, data: data)
					print("Albireo V1 GET [\(requestID)] response: \(message)")
					completion(false, message)
					finish()
					return
				}
				saveAlbireoCookies(response: response)
			}

			guard let data else {
				completion(false, "Server returned no data.")
				finish()
				return
			}
			completion(true, data)
			finish()
		}.resume()
	}
}

// MARK: - Albireo Server APIs
func loginAlbireoServer(server:String,
                 username: String,
                 password: String,
                 completion: @escaping (Bool, String) -> Void) {
    settingsHandler.setAlbireoServerAddr(serverInfo: server)
	if var urlstr = getAlbireoServer(){

		urlstr.append("/api/user/login")

		let postdata = ["name": username, "password": password, "remmember": true] as [String : Any]
		print(urlstr)

		postServer(urlString: urlstr, postdata: postdata) { result, data in
			if result{
				do{
					if let JSON = try jsonDecoder.decode([String: String]?.self, from: data as! Data){
						if let status = JSON["msg"] {
							print(status)
							settingsHandler.setAlbireoAuthMode(.legacyCookie)
							completion(true, status)
						}
						if let status = JSON["message"] {
							clearCookie()
							completion(false, status)
						}
					}
				}catch{
					completion(false, "Json decode error, is server down?")
				}
			}else{
				print("result is false, data is \(data)")
				completion(false, data as! String)
			}
		}
	}else {
		completion(false, "Can not get server address.")
	}

}


func logoutAlbireoServer(completion: @escaping (Bool, String) -> Void) {
    //TODO: logout via API, get method will save cookie couse logout failed
//    var urlstr = getAlbireoServer()
//    urlstr.append("/api/user/logout")
//    getServer(urlString: urlstr) { result, data in
//        if result{
//            do{
//                if let JSON = try jsonDecoder.decode([String: String]?.self, from: data as! Data){
//                    if let status = JSON["msg"] {
//                        print(status)
//                        completion(true, status)
//                    }
//                    if let status = JSON["message"] {//logout failed?
//                        print(status)
//                        completion(false, status)
//                    }
//                }
//            }catch{
//                completion(false, "there is a problem with json decode")
//            }
//        }else{
//            completion(false, data as! String)
//        }
//    }
	settingsHandler.registerSettings()
	let authMode = settingsHandler.getAlbireoAuthMode()
	clearCookie()
	logoutAlbireoV2()
	print("albireo logout success, previous auth mode: \(authMode.rawValue)")
	completion(true, "logout success")
}

func getAlbireoUserInfo(completion: @escaping (Bool, Any?) -> Void){
	if var urlstr = getAlbireoServer(){
		urlstr.append("/api/user/info")
		if loadAlbireoCookies(){
			getServer(urlString: urlstr) { result, data in
				if result{
					let d = data as! Data
						//                print("d:\(String(data: d, encoding: .utf8))")
					if !d.isEmpty{
						do {
							if let userInfo = try jsonDecoder.decode(AlbireoV1UserInfoData?.self, from: d){
								if let msg = userInfo.message{
									completion(false, msg)
								}else{
									print(userInfo)
									completion(true, userInfo)
								}
							}else{
								completion(false, data as! String)
							}
						}catch{
							completion(false, "there is a problem with json decode")
						}
					}else{
						completion(false, "userInfo data is empty!")
					}

				}else{
					completion(false, data as! String)
				}
			}
		}else{
			completion(false, "no cookies!")
		}
	}else{
		completion(false, "Can not get server address.")
	}
}


func getAlbireoMyBangumiList(completion: @escaping (Bool, Any?) -> Void) {
	if var urlstr = getAlbireoServer(){
		urlstr.append("/api/home/my_bangumi?status=3")
		if loadAlbireoCookies(){
			getServer(urlString: urlstr) { result, data in
				if result{
					do {
						if let list = try jsonDecoder.decode(BangumiList?.self, from: data as! Data){
							var items = list.data ?? []
							for index in items.indices {
								items[index].applyCoverImageFallback()
							}
							completion(true, items)
						}else{
							completion(false, data as! String)
						}
					}catch{
						completion(false, "there is a problem with json decode")
					}

				}else{
					completion(false, data as! String)
				}
			}
		}
	}else{
		completion(false, "Can not get server address.")
	}
}

func getAlbireoOnAirList(completion: @escaping (Bool, Any?) -> Void) {
	if var urlstr = getAlbireoServer(){
		urlstr.append("/api/home/on_air")
		if loadAlbireoCookies(){
			getServer(urlString: urlstr) { result, data in
				if result{
					do {
						if let list = try jsonDecoder.decode(BangumiList?.self, from: data as! Data){
							var items = list.data ?? []
							for index in items.indices {
								items[index].applyCoverImageFallback()
							}
							completion(true, items)
						}else{
							completion(false, data as! String)
						}
					}catch{
						completion(false, "there is a problem with json decode")
					}

				}else{
					completion(false, data as! String)
				}
			}
		}
	}else{
		completion(false, "Can not get server address.")
	}
}

func getAlbireoAllBangumiList(page: Int,
                       name: String,
                       completion: @escaping (Bool, Any?) -> Void) {
	if var urlstr = getAlbireoServer(){
		urlstr.append("/api/home/bangumi?page=")
		urlstr.append(String(page))
		urlstr.append("&count=-1&sort_field=air_date&sort_order=desc")
		if name.lengthOfBytes(using: .utf8) > 0{
			urlstr.append("&name=")
			urlstr.append(name)
		}
		urlstr.append("&type=-1")
		if loadAlbireoCookies(){
			getServer(urlString: urlstr) { result, data in
				if result{
					do {
							//Use OnAir model for temp
						if let list = try jsonDecoder.decode(BangumiList?.self, from: data as! Data){
							var items = list.data ?? []
							for index in items.indices {
								items[index].applyCoverImageFallback()
							}
							completion(true, items)
						}else{
							completion(false, data as! String)
						}
					}catch{
						completion(false, "there is a problem with json decode")
					}

				}else{
					completion(false, data as! String)
				}
			}
		}
	}else{
		completion(false, "Can not get server address.")
	}
}
func getAlbireoBangumiDetail(id: String,
                      completion: @escaping (Bool, Any?) -> Void) {
	if var urlstr = getAlbireoServer(){
		urlstr.append("/api/home/bangumi/")
		urlstr.append(id)
		if loadAlbireoCookies(){
			print(urlstr)
			getServer(urlString: urlstr) { result, data in
				if result{
					do {
						if let detail = try jsonDecoder.decode(BGMDetailDataModel?.self, from: data as! Data){
							var normalizedDetail = detail.data
							normalizedDetail.applyCoverImageFallback()
							completion(true, normalizedDetail)
						}else{
							completion(false, data as! String)
						}
					}catch{
						completion(false, "there is a problem with json decode")
					}
				}else{
					completion(false, data as! String)
				}
			}
		}
	}else {
		completion(false, "Can not get server address.")
	}
}
func getAlbireoEPDetail(ep_id: String,
                      completion: @escaping (Bool, Any?) -> Void) {
	settingsHandler.registerSettings()
	if settingsHandler.getAlbireoAuthMode() == .albireoV2OAuth {
		getAlbireoV2EpisodeDetail(epID: ep_id) { result, data in
			completion(result, data)
		}
		return
	}

	if var urlstr = getAlbireoServer(){
		urlstr.append("/api/home/episode/")
		urlstr.append(ep_id)
		if loadAlbireoCookies(){
			getServer(urlString: urlstr) { result, data in
				if result{
					do {
						if let epDetail = try jsonDecoder.decode(EpisodeDetailModel?.self, from: data as! Data){
							var normalizedEpisode = epDetail
							if var bangumi = normalizedEpisode.bangumi {
								bangumi.applyCoverImageFallback()
								normalizedEpisode.bangumi = bangumi
							}
							completion(true, normalizedEpisode)
						}else{
							completion(false, data as! String)
						}
					}catch{
						print(error)
						completion(false, "there is a problem with json decode")
					}
				}else{
					completion(false, data as! String)
				}
			}

		}
	}else {
		completion(false, "Can not get server address.")
	}
}

func sentAlbireoEPWatchProgress(ep_id: String,
                         bangumi_id:String,
                         last_watch_position:Double,
                         percentage:Double,
                         is_finished:Bool,
                         completion: @escaping (Bool, Any?) -> Void){
	settingsHandler.registerSettings()
	if settingsHandler.getAlbireoAuthMode() == .albireoV2OAuth {
		syncAlbireoV2EpisodeWatchProgress(
			epID: ep_id,
			bangumiID: bangumi_id,
			lastWatchPosition: last_watch_position,
			percentage: percentage,
			isFinished: is_finished,
			completion: completion
		)
		return
	}

	if var urlstr = getAlbireoServer(){
		urlstr.append("/api/watch/history/")
		urlstr.append(ep_id)
		if loadAlbireoCookies(){
			let postdata = ["bangumi_id": bangumi_id,
							"last_watch_position": last_watch_position,
							"percentage": percentage,
							"is_finished":is_finished] as [String: Any]

			postServer(urlString: urlstr, postdata: postdata) { result, data in
				if result{
					if let d = data as? Data{
						let s = String(data: d, encoding: .utf8)
						completion(true, s)
					}
				}else{
					completion(false, data as! String)
				}
			}

		}
	}else{
		completion(false, "Can not get server address.")
	}
}

func changeAlbireoFavStatus(bangumi_id:String,
                     status:Int,
                     completion: @escaping (Bool, Any?) -> Void){
	let settingsHandler = SettingsHandler()
	settingsHandler.registerSettings()
	if settingsHandler.getAlbireoAuthMode() == .albireoV2OAuth {
		changeAlbireoV2FavoriteStatus(bangumiID: bangumi_id, status: status, completion: completion)
		return
	}

	if var urlstr = getAlbireoServer(){
		urlstr.append("/api/watch/favorite/bangumi/")
		urlstr.append(bangumi_id)
		if loadAlbireoCookies(){
			let postdata = ["status": status] as [String: Any]

			postServer(urlString: urlstr, postdata: postdata) { result, data in
				if result{
					if let d = data as? Data{
						let s = String(data: d, encoding: .utf8)
						completion(true, s)
					}
				}else{
					completion(false, data as! String)
				}
			}

		}
	}else{
		completion(false, "Can not get server address.")
	}
}
