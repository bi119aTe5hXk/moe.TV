//
//  BGMTVServerHandler.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/16.
//

import Foundation
#if !os(tvOS)
import SafariServices
#endif
private let settingsHandler:SettingsHandler = SettingsHandler()
private let jsonDecoder = JSONDecoder()

private let baseBGMTVAPIURL = "https://api.bgm.tv"

func isBGMTVlogined() -> Bool {
    let token = settingsHandler.getBGMTVAccessToken()
    if token.isEmpty{
        print("BGMTVAccessToken is empty")
        return false
    }else{
        //print("BGMTVAccessToken:\(token)")
        return true
    }
}
func logoutBGMTV(){
    settingsHandler.setBGMTVAccessToken(token: "")
    settingsHandler.setBGMTVRefreshToken(token: "")
    settingsHandler.setBGMTVExpireTime(time: 0)
    print("bgm.tv auth cleared")
}

private func patchServer(urlString:String,
                          postdata:[String:Any],
                        completion:@escaping (Bool, Any) -> Void) {
    do{
        print(urlString)
        guard let url = URL(string: urlString) else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = try JSONSerialization.data(withJSONObject: postdata, options: .prettyPrinted)
        request.setValue("Bearer \(settingsHandler.getBGMTVAccessToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request){(data, response, error) in
            //print(response)
            if let err = error {
                completion(false, err.localizedDescription)
            }
			if let r = response as? HTTPURLResponse{
				if r.statusCode < 200 || r.statusCode >= 300{
					completion(false, "Server HTTP status code \(r.statusCode) error.")
					return
				}
			}
            guard let data = data else{return}
            completion(true, String.init(data: data, encoding: .utf8) as Any)
        }.resume()
    }catch{
        completion(false, "Cannot convert postdata to json")
    }
}
private func putServer(urlString:String,
                        postdata:[String:Any],
                      completion:@escaping (Bool, Any) -> Void) {
    do{
        print(urlString)
        guard let url = URL(string: urlString) else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: postdata, options: .prettyPrinted)
        request.setValue("Bearer \(settingsHandler.getBGMTVAccessToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request){(data, response, error) in
            //print(response)
            if let err = error {
                completion(false, err.localizedDescription)
            }
			if let r = response as? HTTPURLResponse{
				if r.statusCode < 200 || r.statusCode >= 300{
					completion(false, "Server HTTP status code \(r.statusCode) error.")
					return
				}
			}
            guard let data = data else{return}
            completion(true, String.init(data: data, encoding: .utf8) as Any)
        }.resume()
    }catch{
        completion(false, "Cannot convert postdata to json")
    }
}
private func getServer(urlString:String,
                      completion: @escaping (Bool, Any) -> Void) {
    print(urlString)
    guard let url = URL(string: urlString) else {return}
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(settingsHandler.getBGMTVAccessToken())", forHTTPHeaderField: "Authorization")

    URLSession.shared.dataTask(with: request){(data, response, error) in
        if let err = error {
            completion(false, err.localizedDescription)
            return
        }
		if let r = response as? HTTPURLResponse{
			if r.statusCode < 200 || r.statusCode >= 300{
				completion(false, "Server HTTP status code \(r.statusCode) error.")
				return
			}
		}
        completion(true, data as Any)
    }.resume()
}
private func postServer(urlString:String,
                         postdata:Dictionary<String,Any>,
						withAccessToken:Bool,
                       completion:@escaping (Bool, Any) -> Void) {
    do{
        print(urlString)
        guard let url = URL(string: urlString) else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		if withAccessToken{
			request.setValue("Bearer \(settingsHandler.getBGMTVAccessToken())", forHTTPHeaderField: "Authorization")
		}
        request.httpBody = try JSONSerialization.data(withJSONObject: postdata, options: .prettyPrinted)
        URLSession.shared.dataTask(with: request){(data, response, error) in
            if let err = error {
                completion(false, err.localizedDescription)
                return
            }
			if let r = response as? HTTPURLResponse{
				if r.statusCode < 200 || r.statusCode >= 300{
					completion(false, "Server HTTP status code \(r.statusCode) error.")
					return
				}
			}
            completion(true, data as Any)
        }.resume()
    }catch{
        completion(false, "Cannot convert postdata to json")
    }
}


// MARK: - bgm.tv Oauth
func startBGMTVLogin() {
    let urlString = "https://bgm.tv/oauth/authorize?client_id=\(bgmAppID)&response_type=code&redirect_uri=moetv%3A%2F%2Fbgmtv"
#if !os(tvOS)
    openURL(urlString: urlString)
#endif
}

func getBGMTVAccessToken(code:String){
    let urlString = "https://bgm.tv/oauth/access_token"
    
    let postdata = ["grant_type":"authorization_code",
                    "client_id":"\(bgmAppID)",
                    "client_secret":"\(bgmAppSecret)",
                    "code":"\(code)",
                    "redirect_uri":"moetv%3A%2F%2Fbgmtv"] as [String:Any]
    
	postServer(
		urlString: urlString,
		postdata: postdata,
		withAccessToken: false
	) { result, data in
        if result{
            do{
                if let r = try jsonDecoder.decode(BGMTVOauthAccessTokenModel?.self, from: data as! Data){
                    if let accesstoken = r.access_token{
						saveBGMLoginInfo(username: nil,
										 accessToken: accesstoken,
                                         refreshToken: r.refresh_token!,
                                         expireIn: r.expires_in!)
                    }else{
                        print("get bgm.tv access token error -1")
                    }
                }else{
                    print("json decode error -1")
                }
            }catch{
                print("json decode error")
            }
        }else{
            print("get bgm.tv access token error")
        }
    }
}


func refreshBGMTVToken(){
    let urlString = "https://bgm.tv/oauth/access_token"
    let refreshToken = settingsHandler.getBGMTVRefreshToken()
    let postdata = ["grant_type":"refresh_token",
                    "client_id":"\(bgmAppID)",
                    "client_secret":"\(bgmAppSecret)",
                    "refresh_token":"\(refreshToken)",
                    "redirect_uri":"moetv%3A%2F%2Fbgmtv"] as [String:Any]
	postServer(
		urlString: urlString,
		postdata: postdata,
		withAccessToken: false
	) { result, data in
        if result{
            do{
                if let r = try jsonDecoder.decode(BGMTVOauthAccessTokenModel?.self, from: data as! Data){
                    if let accesstoken = r.access_token{
//                        print(r)
						saveBGMLoginInfo(username: nil,
										 accessToken: accesstoken,
                                         refreshToken: r.refresh_token!,
                                         expireIn: r.expires_in!)
                    }else{
                        print("refresh bgm.tv token error -1, logout")
                        logoutBGMTV()
                    }
                }else{
                    print("json decode error -1")
                }
            }catch{
                print("json decode error")
            }
        }else{
            print("refresh bgm.tv token error")
        }
    }
}

func saveBGMLoginInfo(username:String?, accessToken:String?, refreshToken:String?, expireIn:Int?){
	if let username = username{
		settingsHandler.setBGMTVUsername(username: username)
		print("bgm.tv username saved")
	}
	if let accessToken = accessToken{
		settingsHandler.setBGMTVAccessToken(token: accessToken)
		print("bgm.tv accessToken saved")
	}
	if let refreshToken = refreshToken{
		settingsHandler.setBGMTVRefreshToken(token: refreshToken)
		print("bgm.tv refreshToken saved")
	}
	if let expireIn = expireIn{
		let ts = Int(Date().timeIntervalSince1970) + expireIn
		settingsHandler.setBGMTVExpireTime(time: ts)
		print("bgm.tv ts saved")
	}
}

func isBGMAccessTokenExpired() -> Bool{
    let ts = settingsHandler.getBGMTVExpireTime()
    let now = Int(Date().timeIntervalSince1970)
    
    if now >= ts{
        print("bgm.tv accesstoken expired, refresh required")
        return true
    }
    print("bgm.tv access token \(ts - now)s left")
    return false
}

//func getBGMTokenStatus(completion: @escaping (Bool, Any) -> Void){
//    if isBGMTVlogined(){
//        if isBGMAccessTokenExpired(){
//            refreshBGMTVToken()
//        }
//        let urlString = "https://bgm.tv/oauth/token_status"
//        let postdata = ["access_token":"\(saveHandler.getBGMTVAccessToken())"]
//        postServer(urlString: urlString, postdata: postdata) { result, data in
//            if result{
//                print(String.init(data: data as! Data, encoding: .utf8))
//                do{
//                    if let r = try jsonDecoder.decode(BGMTVOauthTokenStatus?.self, from: data as! Data){
//                        print(r)
//                        if let _ = r.access_token{
//                            completion(true,r)
//                        }else{
//                            completion(false,"oauth failed. access_token missing")
//                        }
//                    }
//                }catch{
//                    print("json decode error")
//                    completion(false,"json decode failed")
//                }
//            }else{
//                completion(false,"oauth failed")
//            }
//        }
//    }
//}


// MARK: - bgm.tv APIs
func getBGMCollectionStatus(subject_id:Int, completion: @escaping (Bool, Any) -> Void){
	if isBGMTVlogined(){
		if isBGMAccessTokenExpired(){
			refreshBGMTVToken()
		}
		if settingsHandler.getBGMTVUsername().isEmpty{
			getBGMTVUserInfo(completion: { (_, _) in})
		}
		let urlStr = "\(baseBGMTVAPIURL)/v0/users/\(settingsHandler.getBGMTVUsername())/collections/\(subject_id)"
		//print(urlStr)
		getServer(urlString: urlStr) { result, data in
			if result{
				do{
					if let collection = try jsonDecoder.decode(BGMTVUserSubjectCollectionModel?.self, from: data as! Data){
						completion(true, collection)
					}else {
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
}

func getBGMCollectionEpisodeList(subject_id:Int, completion: @escaping (Bool, Any) -> Void){
	if isBGMTVlogined(){
		if isBGMAccessTokenExpired(){
			refreshBGMTVToken()
		}
		let urlStr = "\(baseBGMTVAPIURL)/v0/users/-/collections/\(subject_id)/episodes"
		getServer(urlString: urlStr) { result, data in
			//print("\(String.init(data: data as! Data, encoding: .utf8))")

			if result{
				do {
					if let episodeList = try jsonDecoder.decode(BGMTVCollectionEpisodesModel?.self, from: data as! Data){
						completion(true, episodeList)
					}else{
						print("getBGMCollectionEpisodeList inner failed: \(data as! String)")
						completion(false, data as! String)
					}
				}catch{
					print("getBGMCollectionEpisodeList json decode failed: \(error.localizedDescription)")
					completion(false, "there is a problem with json decode")
				}
			}else{
				print("getBGMCollectionEpisodeList outter failed: \(data as! String)")
				completion(false, data as! String)
			}
		}



	}
}
func setBGMCollectionStatus(subject_id:Int, status:Int, completion: @escaping (Bool, Any) -> Void){
    if isBGMTVlogined(){
        if isBGMAccessTokenExpired(){
            refreshBGMTVToken()
        }
        let urlStr = "\(baseBGMTVAPIURL)/v0/users/-/collections/\(subject_id)"
		postServer(urlString: urlStr,
				   postdata: ["type":status],
				   withAccessToken: true
		) { result, data in
            completion(result,data)
        }
    }
}

func setBGMEPWatched(epID:Int, completion: @escaping (Bool, Any) -> Void){
    if isBGMTVlogined(){
        if isBGMAccessTokenExpired(){
            refreshBGMTVToken()
        }
        let urlStr = "\(baseBGMTVAPIURL)/v0/users/-/collections/-/episodes/\(epID)"
        putServer(urlString: urlStr,
                  postdata: ["type":2]) { result, data in
            completion(result,data)
        }
    }
}
func setBGMSBEPStatues(subject_id:Int,episode_id:Int,status:Int,completion: @escaping (Bool, Any) -> Void){
    if isBGMTVlogined(){
        if isBGMAccessTokenExpired(){
            refreshBGMTVToken()
        }
        let urlstr = "\(baseBGMTVAPIURL)/v0/users/-/collections/\(subject_id)/episodes"
        patchServer(urlString: urlstr, postdata: ["episode_id":[episode_id],"type":status]) { result, data in
            completion(result,data)
        }
    }
}



func getBGMTVUserInfo(completion: @escaping (Bool, Any) -> Void){
    if isBGMTVlogined(){
        if isBGMAccessTokenExpired(){
            refreshBGMTVToken()
        }
        let urlstr = "\(baseBGMTVAPIURL)/v0/me"
        getServer(urlString: urlstr) { result, data in
            if result{
                do {
                    if let u = try jsonDecoder.decode(BGMTVUserInfoModel?.self, from: data as! Data){
						saveBGMLoginInfo(username: u.username ?? nil,
										 accessToken: nil,
										 refreshToken: nil,
										 expireIn: nil)
                        completion(true, u)
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
}

