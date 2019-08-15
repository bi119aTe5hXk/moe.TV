//
//  ServerHandler.swift
//  moe.TV
//
//  Created by billgateshxk on 2019/08/15.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import Foundation

func getServerAddr() -> String {
    return UserDefaults.standard.string(forKey: "serveraddr")!
}
func logInServer(username:String, password:String, completion: @escaping (Any?, String?) -> Void) {
    
}


func getMyBangumiList(completion: @escaping (Any?, String?) -> Void) {
    
}

func getOnAirList(completion: @escaping (Any?, String?) -> Void) {
    
}

func getAllBangumiList(page:Int, name:String, completion: @escaping (Any?, String?) -> Void) {
    
}
func getBangumiDetail(id:String, completion: @escaping (Any?, String?) -> Void) {
    
}
func getEpisodeDetail(ep_id:String,completion: @escaping (Any?, String?) -> Void) {
    
}
