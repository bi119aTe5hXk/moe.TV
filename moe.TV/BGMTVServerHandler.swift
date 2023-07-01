//
//  BGMTVServerHandler.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/16.
//

import Foundation
import SafariServices

private let saveHandler:SaveHandler = SaveHandler()
private let jsonDecoder = JSONDecoder()

private let baseBGMTVAPIURL = "https://api.bgm.tv"

struct BGMTVOauthAccessTokenModel : Codable {
    let access_token:String?
    let expires_in:Int?
    let token_type:String?
    let scope:String?
    let refresh_token:String?
}

func isBGMTVlogined() -> Bool {
    return !saveHandler.getBGMTVAccessToken().isEmpty
}
func logoutBGMTV(){
    saveHandler.setBGMTVAccessToken(token: "")
    saveHandler.setBGMTVRefreshToken(token: "")
    saveHandler.setBGMTVExpireTime(time: 0)
}

func startBGMTVLogin() {
    let urlString = "https://bgm.tv/oauth/authorize?client_id=\(bgmAppID)&response_type=code&redirect_uri=moetv%3A%2F%2Fbgmtv"
    openURL(urlString: urlString)
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
    print("bgm.tv oauth login compete")
}

func isBGMAccessTokenExpired() -> Bool{
    let ts = saveHandler.getBGMTVExpireTime()
    let now = Int(Date().timeIntervalSince1970)
    
    if now >= ts{
        return true
    }
    return false
}

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
private func postServer(urlString:String,
                postdata:Dictionary<String,Any>,
                completion: @escaping (Bool, Any) -> Void) {
    do{
        print(urlString)
        guard let url = URL(string: urlString) else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
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
