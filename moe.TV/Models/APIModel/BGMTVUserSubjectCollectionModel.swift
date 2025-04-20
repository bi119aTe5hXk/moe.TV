//
//  BGMTVUserSubjectCollectionModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2025/04/20.
//

import Foundation
struct BGMTVUserSubjectCollectionModel: Decodable {
	let subject_id:Int
	let subject_type:Int //1=books,2=anime,3=music,4=game,6=real
	let rate:Int
	let type:Int //1=want,2=watched,3=watching,4=pause,5=abandoned
	let comment:String?
	
	let ep_status:Int
	let vol_status:Int
}
