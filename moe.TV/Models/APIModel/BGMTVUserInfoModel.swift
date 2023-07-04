//
//  BGMTVUserInfoModel.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/07/05.
//

import Foundation
struct BGMTVUserInfoModel:Codable{
    let avatar:BGMTVUserAvatar?
    let sign:String?
    let username:String?
    let nickname:String?
    let id:Int?
    let user_group:Int?
}
struct BGMTVUserAvatar:Codable{
    let large:String?
    let medium:String?
    let small:String?
}
