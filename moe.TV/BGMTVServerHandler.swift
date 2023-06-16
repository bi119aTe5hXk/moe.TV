//
//  BGMTVServerHandler.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/16.
//

import Foundation
import OAuthSwift

private let saveHandler:SaveHandler = SaveHandler()
private var oauthswift: OAuth2Swift?

private let baseBGMTVAPIURL = "https://api.bgm.tv"


func isBGMTVlogined() -> Bool {
    return !saveHandler.getBGMTVAccessToken().isEmpty
}
func logoutBGMTV(){
    saveHandler.setBGMTVAccessToken(token: "")
}

func loginBGMServer(completion: @escaping (Bool, Any) -> Void) {
    oauthswift = OAuth2Swift(
        consumerKey:    bgmAppID,
        consumerSecret: bgmAppSecret,
        authorizeUrl: "https://bgm.tv/oauth/authorize",
        accessTokenUrl:"https://bgm.tv/oauth/access_token",
        responseType: "code"
    )
    oauthswift?.accessTokenBasicAuthentification = true
    let _ = oauthswift?.authorize(
        withCallbackURL: "moetv://bgmtv/callback",
        scope: "",
        state:UUID().uuidString) { result in
        switch result {
        case .success(let (credential, response, parameters)):
            print(credential.oauthToken)
            saveHandler.setBGMTVAccessToken(token: credential.oauthToken)
            saveHandler.setBGMTVRefreshToken(token: credential.oauthRefreshToken)
            completion(true, credential.oauthToken)
        case .failure(let error):
            print(error.localizedDescription)
            completion(false, error.localizedDescription)
        }
    }
}
//TODO: Refresh oauth token
//func refreshToken(completion: @escaping (Bool, Any) -> Void){
//    oauthswift?.renewAccessToken(withRefreshToken: saveHandler.getBGMTVRefreshToken(), completionHandler: { result in
//        switch result {
//        case .success(let (credential, response, parameters)):
//            print(credential.oauthToken)
//            saveHandler.setBGMTVAccessToken(token: credential.oauthToken)
//            saveHandler.setBGMTVRefreshToken(token: credential.oauthRefreshToken)
//            completion(true, credential.oauthToken)
//        case .failure(let error):
//            print(error.localizedDescription)
//            completion(false, error.localizedDescription)
//        }
//    })
//}

func updateBGMEPwatched(epID:Int, completion: @escaping (Bool, Any) -> Void){
    if isBGMTVlogined(){
        let urlStr = "\(baseBGMTVAPIURL)/v0/users/-/collections/-/episodes/\(epID)"
        putServer(urlString: urlStr,
                  postdata: ["type":2]) { result, data in
            completion(result,data)
        }
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
            if let err = error {
                completion(false, err.localizedDescription)
            }
            guard let data = data else{return}

            completion(true, String.init(data: data, encoding: .utf8))
        }.resume()
    }catch{
        completion(false, "Cannot convert postdata to json")
    }
    
}
