//
//  BangumiListModel.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/10.
//
import Foundation


struct MyBangumiItemModel: Identifiable, Hashable{
    let id:String
    var bgm_id:Int //the id of this bangumi in bgm.tv
    var name:String //the original name (usually the original language) of the bangumi
    var name_cn:String? = "" //the chinese translated name of the bangumi, can be null.
    var summary:String? = "" //description for bangumi, can be null
    var cover_image_url:String? = "" //the original image url from bgm.tv, this should not be used except the bangumi is not saved into database yet. A client should use cover property.
    var type:Int
    var status:Int //status of a bangumi, can be 0 (pending), 1 (on air), 2 (finished)
    var air_weekday:Int //Which day of a week this bangumi is on air.
    var eps:Int //how many episodes the bangumi has
    var favorite_status:Int //current favorite status of the bangumi, this field can be one of the following value: 1 (WISH), 2 (WATCHED), 3 (WATCHING), 4 (PAUSE), 5 (ABANDONED)
    var unwatched_count:Int? = 0 //how many episodes which is downloaded but not been watched by current user.
    
}

let testBangumiItem1 = MyBangumiItemModel.init(
    id: UUID().uuidString,
    bgm_id: 174138,
    name: "喜羊羊与灰太狼",
    name_cn: "喜羊羊与灰太狼",
    summary: "羊历3010年（故事中的虚构历法），一个绵羊群的先祖为了避开狼群的追杀而去到“青青草原”，并建立了一个有着坚固防御的小村。...",
    cover_image_url: "http://lain.bgm.tv/pic/cover/l/05/2a/13131_1GmZy.jpg",
    type: 2,
    status: 1,
    air_weekday: 6,
    eps: 1,
    favorite_status: 3
)
let testBangumiItem2 = MyBangumiItemModel.init(
    id: UUID().uuidString,
    bgm_id: 174139,
    name: "喜羊羊与灰太狼2",
    name_cn: "喜羊羊与灰太狼2",
    summary: "羊历3010年（故事中的虚构历法），一个绵羊群的先祖为了避开狼群的追杀而去到“青青草原”，并建立了一个有着坚固防御的小村。...",
    cover_image_url: "http://lain.bgm.tv/pic/cover/l/05/2a/13131_1GmZy.jpg",
    type: 2,
    status: 0,
    air_weekday: 6,
    eps: 11,
    favorite_status: 1,
    unwatched_count: 5
)
let testBangumiItem3 = MyBangumiItemModel.init(
    id: UUID().uuidString,
    bgm_id: 174539,
    name: "喜羊羊与灰太狼33",
    name_cn: "喜羊羊与灰太狼3",
    summary: "羊历3010年（故事中的虚构历法），一个绵羊群的先祖为了避开狼群的追杀而去到“青青草原”，并建立了一个有着坚固防御的小村。...",
    cover_image_url: "http://lain.bgm.tv/pic/cover/l/05/2a/13131_1GmZy.jpg",
    type: 2,
    status: 2,
    air_weekday: 6,
    eps: 5,
    favorite_status: 2,
    unwatched_count: 1
)



