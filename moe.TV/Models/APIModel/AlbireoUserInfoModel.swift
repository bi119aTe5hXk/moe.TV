//
//  AlbireoUserInfoModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/04.
//

import Foundation
struct AlbireoUserInfoData: Codable{
    let data:AlbireoUserInfo?
}
struct AlbireoUserInfo: Codable{
    let name:String?
    let level:Int?
    let email:String?
    let email_confirmed:Bool?
}
