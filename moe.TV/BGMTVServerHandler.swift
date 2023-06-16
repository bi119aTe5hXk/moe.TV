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

    let handle = oauthswift?.authorize(
        withCallbackURL: "moetv://bgmtv/callback",
        scope: "",
        state:"moetv") { result in
        switch result {
        case .success(let (credential, response, parameters)):
            print(credential.oauthToken)
            saveHandler.setBGMTVAccessToken(token: credential.oauthToken)
            completion(true, credential.oauthToken)
        case .failure(let error):
            print(error.localizedDescription)
            completion(false, error.localizedDescription)
        }
    }
}

func updateBGMEPwatched(epID:Int, completion: @escaping (Bool, Any) -> Void){
    if isBGMTVlogined(){
        let urlStr = "\(baseBGMTVAPIURL)/v0/users/-/collections/-/episodes/\(epID)"
        putServer(urlString: urlStr,
                  body: ["type":2]) { result, data in
            completion(result,data)
        }
    }
}


private func putServer(urlString:String,
                       body:[String:Any],
               completion: @escaping (Bool, Any) -> Void) {
    guard let url = URL(string: urlString) else {return}
    let headers = ["User-Agent":userAgent,
                   "Content-Type":"application/json; charset=utf-8"]
    oauthswift?.client.request(url,
                               method: .PUT,
                               parameters: body,
                               headers: headers,
                               checkTokenExpiration: true,
                               completionHandler: { result in
        switch result {
        case .success(let response):
            completion(true, response.data)
        case .failure(let error):
            print(error.localizedDescription)
            completion(false, error.localizedDescription)
        }
    })
}
