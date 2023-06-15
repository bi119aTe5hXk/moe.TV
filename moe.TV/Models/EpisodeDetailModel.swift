//
//  EpisodeDetailModel.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/13.
//

import Foundation

struct EpisodeDetailModel:Identifiable, Hashable, Codable{
    let id:String
    var bangumi_id:String //Id of bangumi that is the episode belong to.
    var bgm_eps_id:Int //id of this episode in bgm.tv
    var name:String //the original name (usually the original language) of the episode
    var name_cn:String? = "" //the chinese translated name of the bangumi, can be null.
    var summary:String? = "" //description for bangumi, can be null
    var thumbnail:String
    var status:Int //the status of episode, can be: 0 (not downloaded), 1 (downloading), 2 (downloaded)
    var episode_no:Int //the number of the episode
    var duration:String
    var video_files:[videoFilesListModel]
    var watch_progress:watchProgress? //the watch progress information of current episode, can be undefined.
}

struct videoFilesListModel:Identifiable, Hashable, Codable{
    let id:String
    var status:Int //can be 1 (download pending), 2 (downloading), 3 (downloaded)
    var url:String
    var file_path:String
    var file_name:String? //name of actual file, can be null
    var episode_id:String
    var bangumi_id:String
    var duration:Int
}
