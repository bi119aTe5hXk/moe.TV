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


func saveAlbireoCookies(response: HTTPURLResponse) {
    let headerFields = response.allHeaderFields as! [String: String]
    let url = response.url
    
    let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url!)
    var cookieArray = [[HTTPCookiePropertyKey: Any]]()
    for cookie in cookies {
        cookieArray.append(cookie.properties!)
    }
    if cookieArray.count > 0{
        settingsHandler.setAlbireoCookie(array: cookieArray)
		settingsHandler.setAlbireoAuthMode(.legacyCookie)
        print("albireo cookie saved")
    }else{
        print("albireo cookie is empty, skip")
    }
    
}

//return true if have cookie result
func loadAlbireoCookies() -> Bool {
    settingsHandler.registerSettings()
    if let cookieArray = settingsHandler.getAlbireoCookie(), !cookieArray.isEmpty {
        for cookieProperties in cookieArray {
            if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any]) {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
        print("albireo cookie loaded")
        return true
    }else {
        //print("albireo cookie is nil")
        return false
    }
}
func getAllCookies(completion: @escaping (Array<String>) -> Void){
    if let cookieArray = settingsHandler.getAlbireoCookie(){
        var newArr:Array<String> = []
        for cookieProperties in cookieArray {
            if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any]) {
                print("\(cookie)")
                newArr.append("\(cookie)")
            }
        }
        
        completion(newArr)
    }
}
func clearCookie(){
    settingsHandler.setAlbireoCookie(array: [])
    HTTPCookieStorage.shared.cookies?.forEach { cookie in
        HTTPCookieStorage.shared.deleteCookie(cookie)
    }
    print("albireo cookie cleared")
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
    //print("connecting server via POST")
    do{
        print(urlString)
        guard let url = URL(string: urlString) else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: postdata, options: .prettyPrinted)
        request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request){(data, response, error) in
            if let err = error {
                completion(false, err.localizedDescription)
            }
            guard let data = data else{return}

			if let r = response as? HTTPURLResponse{
				if r.statusCode < 200 || r.statusCode >= 300{
					completion(false, "Server HTTP status code \(r.statusCode) error.")
					return
				}else{
					saveAlbireoCookies(response: r)
				}
			}
            completion(true, data)
        }.resume()
    }catch{
        completion(false, "Cannot convert postdata to json")
    }
    
}

private func getServer(urlString:String,
               completion: @escaping (Bool, Any) -> Void) {
    //print("connecting server via GET:\(urlString)")
    guard let url = URL(string: urlString) else {return}
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.setValue(AppConstants.userAgent, forHTTPHeaderField: "User-Agent")
    URLSession.shared.dataTask(with: request){(data, response, error) in
        if let err = error {
            completion(false, err.localizedDescription)
        }
		if let r = response as? HTTPURLResponse{
			if r.statusCode < 200 || r.statusCode >= 300{
				completion(false, "Server HTTP status code \(r.statusCode) error.")
				return
			}else{
				saveAlbireoCookies(response: r)
			}
		}
        guard let data = data else{return}
        completion(true, data)
    }.resume()
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
