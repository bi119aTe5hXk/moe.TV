//
//  BGMTVServerHandler.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/16.
//

import Foundation
#if !os(tvOS)
import SafariServices
#endif
private let saveHandler:SaveHandler = SaveHandler()
private let jsonDecoder = JSONDecoder()

private let baseBGMTVAPIURL = "https://api.bgm.tv"

func isBGMTVlogined() -> Bool {
    return !saveHandler.getBGMTVAccessToken().isEmpty
}
func logoutBGMTV(){
    saveHandler.setBGMTVAccessToken(token: "")
    saveHandler.setBGMTVRefreshToken(token: "")
    saveHandler.setBGMTVExpireTime(time: 0)
}

private func patchServer(urlString:String,
                       postdata:[String:Any],
               completion: @escaping (Bool, Any) -> Void) {
    do{
        print(urlString)
        guard let url = URL(string: urlString) else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = try JSONSerialization.data(withJSONObject: postdata, options: .prettyPrinted)
        request.setValue("Bearer \(saveHandler.getBGMTVAccessToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request){(data, response, error) in
            //print(response)
            if let err = error {
                completion(false, err.localizedDescription)
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
               completion: @escaping (Bool, Any) -> Void) {
    do{
        print(urlString)
        guard let url = URL(string: urlString) else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: postdata, options: .prettyPrinted)
        request.setValue("Bearer \(saveHandler.getBGMTVAccessToken())", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request){(data, response, error) in
            //print(response)
            if let err = error {
                completion(false, err.localizedDescription)
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
    request.setValue("Bearer \(saveHandler.getBGMTVAccessToken())", forHTTPHeaderField: "Authorization")

    URLSession.shared.dataTask(with: request){(data, response, error) in
        if let err = error {
            completion(false, err.localizedDescription)
            return
        }
        completion(true, data as Any)
    }.resume()
}
private func postServer(urlString:String,
                postdata:Dictionary<String,Any>,
                completion: @escaping (Bool, Any) -> Void) {
    do{
        print(urlString)
        guard let url = URL(string: urlString) else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
//        var requestBodyComponents = URLComponents()
//        postdata.forEach { (key: String, value: Any) in
//            requestBodyComponents.queryItems?.append(URLQueryItem(name: key, value: value as? String))
//        }
//        request.httpBody = requestBodyComponents.query?.data(using: .utf8)
//        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        
        
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: postdata, options: .prettyPrinted)
        URLSession.shared.dataTask(with: request){(data, response, error) in
            if let err = error {
                completion(false, err.localizedDescription)
                return
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
    
    postServer(urlString: urlString, postdata: postdata) { result, data in
        if result{
            do{
                if let r = try jsonDecoder.decode(BGMTVOauthAccessTokenModel?.self, from: data as! Data){
                    if let accesstoken = r.access_token{
                        saveBGMLoginInfo(accessToken: accesstoken,
                                         refreshToken: r.refresh_token!,
                                         expireIn: r.expires_in!)
                    }
                }
            }catch{
                print("json decode error")
            }
        }
    }
}


func refreshBGMTVToken(){
    let urlString = "https://bgm.tv/oauth/access_token"
    let refreshToken = saveHandler.getBGMTVRefreshToken()
    let postdata = ["grant_type":"refresh_token",
                    "client_id":"\(bgmAppID)",
                    "client_secret":"\(bgmAppSecret)",
                    "refresh_token":"\(refreshToken)",
                    "redirect_uri":"moetv%3A%2F%2Fbgmtv"] as [String:Any]
    postServer(urlString: urlString, postdata: postdata) { result, data in
        if result{
            do{
                if let r = try jsonDecoder.decode(BGMTVOauthAccessTokenModel?.self, from: data as! Data){
                    if let accesstoken = r.access_token{
                        saveBGMLoginInfo(accessToken: accesstoken,
                                         refreshToken: r.refresh_token!,
                                         expireIn: r.expires_in!)
                    }
                }
            }catch{
                print("json decode error")
            }
        }
    }
}

func saveBGMLoginInfo(accessToken:String, refreshToken:String, expireIn:Int){
    let ts = Int(Date().timeIntervalSince1970) + expireIn
    
    saveHandler.setBGMTVAccessToken(token: accessToken)
    saveHandler.setBGMTVRefreshToken(token: refreshToken)
    saveHandler.setBGMTVExpireTime(time: ts)
    print("bgm.tv oauth token saved")
}

func isBGMAccessTokenExpired() -> Bool{
    let ts = saveHandler.getBGMTVExpireTime()
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


func updateBGMEPwatched(epID:Int, completion: @escaping (Bool, Any) -> Void){
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
func updateBGMSBEPwatched(subject_id:Int,episode_id:Int,completion: @escaping (Bool, Any) -> Void){
    if isBGMTVlogined(){
        if isBGMAccessTokenExpired(){
            refreshBGMTVToken()
        }
        let urlstr = "\(baseBGMTVAPIURL)/v0/users/-/collections/\(subject_id)/episodes"
        patchServer(urlString: urlstr, postdata: ["episode_id":[episode_id],"type":2]) { result, data in
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
            print(String.init(data: data as! Data, encoding: .utf8) as Any)
            if result{
                do {
                    if let u = try jsonDecoder.decode(BGMTVUserInfoModel?.self, from: data as! Data){
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

