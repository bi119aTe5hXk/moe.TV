//
//  ServerHandler.swift
//  moe.TV
//
//  Created by billgateshxk on 2019/08/15.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//
import SwiftyJSON
import Alamofire
import Foundation

func getServerAddr() -> String {
    return UserDefaults.standard.string(forKey: "serveraddr")!
}
func logInServer(username:String, password:String, completion: @escaping (Any?, String?) -> Void) {
    var urlstr = getServerAddr()
    urlstr.append("/api/user/login")
    
    let postdata = ["name":username, "password":password, "remmember":true] as [String : Any]
    
    AF.request(urlstr, method: .post, parameters: postdata, encoding: JSONEncoding.default).responseJSON { response in
        print(response.result)
    }
}


func getMyBangumiList(completion: @escaping (Any?, String?) -> Void) {
    var urlstr = getServerAddr()
    urlstr.append("/api/home/my_bangumi?status=3")
}

func getOnAirList(completion: @escaping (Any?, String?) -> Void) {
    
}

func getAllBangumiList(page:Int, name:String, completion: @escaping (Any?, String?) -> Void) {
    
}
func getBangumiDetail(id:String, completion: @escaping (Any?, String?) -> Void) {
    
}
func getEpisodeDetail(ep_id:String,completion: @escaping (Any?, String?) -> Void) {
    
}



