//
//  AlbireoV1UserInfoModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/04.
//

import Foundation
struct AlbireoV1UserInfoData: Codable{
    let data:AlbireoV1UserInfo?
    let message:String?
}
struct AlbireoV1UserInfo: Codable{
    let name:String?
    let level:Int?
    let email:String?
    let email_confirmed:Bool?
}
