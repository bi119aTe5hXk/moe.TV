//
//  BangumiDetailModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/13.
//

import Foundation
struct BGMDetailDataModel: Codable{
    var data:BangumiDetailModel
}
struct BangumiDetailModel:Identifiable, Hashable, Codable{
    let id:String
    var bgm_id:Int //the id of this bangumi in bgm.tv
    var name:String //the original name (usually the original language) of the bangumi
    var name_cn:String? = "" //the chinese translated name of the bangumi, can be null.
    var summary:String? = "" //description for bangumi, can be null
    var image:String? = "" //the original image url from bgm.tv, this should not be used except the bangumi is not saved into database yet. A client should use cover property.
    var type:Int
    var status:Int //status of a bangumi, can be 0 (pending), 1 (on air), 2 (finished)
    var air_weekday:Int //Which day of a week this bangumi is on air.
    var eps:Int //how many episodes the bangumi has
    var episodes:[BGMEpisode] //episode list of the bangumi
}

struct BGMEpisode:Identifiable, Hashable, Codable{
    let id:String
    var bangumi_id:String //Id of bangumi that is the episode belong to.
    var bgm_eps_id:Int //id of this episode in bgm.tv
    var name:String //the original name (usually the original language) of the episode
    var name_cn:String? //the chinese translated name of the episode, can be null
    var thumbnail:String
    var status:Int //the status of episode, can be: 0 (not downloaded), 1 (downloading), 2 (downloaded)
    var episode_no:Int //the number of the episode
    var duration:String
    var watch_progress:watchProgress? //the watch progress information of current episode, can be undefined.
}

struct watchProgress:Identifiable, Hashable, Codable{
    let id: String
    var user_id:String //identify which user this watch progress belongs to.
    var last_watch_position:Double //last watched video progress by seconds
    var bangumi_id:String
    var watch_status:Int //can be 1 (WISH), 2 (WATCHED), 3 (WATCHING), 4 (PAUSE), 5 (ABANDONED)
    var episode_id:String
    var percentage:Float //watched percentage of video duration. from 0 ~ 1
}
