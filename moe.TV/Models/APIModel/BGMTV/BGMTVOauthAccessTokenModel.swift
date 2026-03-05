//
//  BGMTVOauthAccessTokenModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/04.
//

import Foundation
struct BGMTVOauthAccessTokenModel: Codable{
    let access_token:String?
    let expires_in:Int?
    let token_type:String?
    let scope:String?
    let refresh_token:String?
    let user_id:Int?
}

//struct BGMTVOauthTokenStatus: Codable{
//    let access_token:String?
//    let expires:Int?
//    let scope:String?
//    let user_id:Int?
//}


