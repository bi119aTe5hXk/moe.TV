//
//  BangumiListModel.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/10.
//
import Foundation

struct MyBangumiList: Codable{
    var data:[MyBangumiItemModel]?
}

struct MyBangumiItemModel: Codable, Hashable, Identifiable{
    let id:String
    var bgm_id:Int? //the id of this bangumi in bgm.tv
    var name:String? //the original name (usually the original language) of the bangumi
    var name_cn:String? = "" //the chinese translated name of the bangumi, can be null.
    var summary:String? = "" //description for bangumi, can be null
    var image:String? = "" //the original image url from bgm.tv, this should not be used except the bangumi is not saved into database yet. A client should use cover property.
    var type:Int?
    var status:Int? //status of a bangumi, can be 0 (pending), 1 (on air), 2 (finished)
    var air_weekday:Int? //Which day of a week this bangumi is on air.
    var eps:Int? //how many episodes the bangumi has
    var favorite_status:Int? //current favorite status of the bangumi, this field can be one of the following value: 1 (WISH), 2 (WATCHED), 3 (WATCHING), 4 (PAUSE), 5 (ABANDONED)
    var unwatched_count:Int? = 0 //how many episodes which is downloaded but not been watched by current user.
}



