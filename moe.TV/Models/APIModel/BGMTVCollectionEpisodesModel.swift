//
//  BGMTVCollectionEpisodesModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2025/04/27.
//

import Foundation
struct BGMTVCollectionEpisodesModel: Decodable {
	let total : Int?
	let limit : Int?
	let offset : Int?
	let data : [BGMTVUserEpisodeCollectionModel]?
}

struct BGMTVUserEpisodeCollectionModel: Decodable {
	let episode : BGMTVEpisodeModel?
	let type : Int? //0=unknown,1=want,2=watched,3=abandoned
}

struct BGMTVEpisodeModel: Decodable {
	let id : Int
	let type : Int?
	let name : String?
	let name_cn : String?
	let sort: Int?
	let ep: Int?
	let airdate: String?
	let comment: Int?
	let subject_id: Int?
	let duration: String?
	let desc: String?
	let disc: Int?
	let duration_seconds: Int?
}
