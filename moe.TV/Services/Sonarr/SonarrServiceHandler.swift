//
//  SonarrServiceHandler.swift
//  moe.TV
//
//  Created by billgateshxk on 2020/03/13.
//  Copyright © 2020 bi119aTe5hXk. All rights reserved.
//
//  Doc for Sonarr: https://github.com/Sonarr/Sonarr/wiki/API

import Foundation

// MARK: - Sonarr Service

//Sonarr
let UD_SONARR_APIKEY = "sonarr_api_key"
let UD_SONARR_USINGBASICAUTH = "sonarr_basic_auth"
let UD_SONARR_USERNAME = "sonarr_username"
let UD_SONARR_PASSWORD = "sonarr_password"
let UD_SONARR_WEBDAV_PORT = "sonarr_webdav_port"
let UD_SONARR_ROOTFOLDER = "sonarr_rootfolder"

func SonarrRegisterUserDefault(){
    let ud = UserDefaults.init(suiteName: UD_SUITE_NAME)!
    ud.register(defaults: [UD_SONARR_APIKEY : ""])
    ud.register(defaults: [UD_SONARR_USERNAME : ""])
    ud.register(defaults: [UD_SONARR_PASSWORD : ""])
    ud.register(defaults: [UD_SONARR_ROOTFOLDER : ""])
    ud.register(defaults: [UD_SONARR_WEBDAV_PORT : 0])
    ud.register(defaults: [UD_SONARR_USINGBASICAUTH : false])
}


func SonarrAddAPIKEY(url:String)->String{
    var urlstr = url
    let apikey = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SONARR_APIKEY)
    
    if (apikey?.lengthOfBytes(using: .utf8))! > 0 {
        urlstr.append("?apikey=\(apikey!)")
        return urlstr
    }else{
        //missing api key, set loggen in to false
        UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
        return ""
    }
}
func SonarrURL()->String{
    var urlstr = ""
    //add http/https prefix
    urlstr = addPrefix(url: urlstr)
    
    //add basic auth info
    urlstr = addBasicAuth(url: urlstr)
    
    //then append host name and port
    urlstr.append(UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
    
    return urlstr
}

func SonarrGetSystemStatus(username:String,
                           password:String,
                           apikey:String,
                           completion: @escaping (Bool, Any?) -> Void) {
    initNetwork()
    var urlstr = ""
    if username.lengthOfBytes(using: .utf8) > 0 || password.lengthOfBytes(using: .utf8) > 0 {
        urlstr =  "\(username):\(password)@"
    }
    
    urlstr.append(UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
    urlstr = addPrefix(url: urlstr)
    
    urlstr.append("/api/system/status")
    //check the api key is valid at first time "login"
    urlstr.append("?apikey=\(apikey)")//DO NOT REPLACE WITH USER DEFAULT (SonarrAddAPIKEY func)
    //print(urlstr)
    connectToService(urlString: urlstr, method: .get, postdata: nil, responseType: "Dictionary") { (isSuccess, result) in
        completion(isSuccess,result)
    }
}

func SonarrGetSeries(id:Int,completion: @escaping (Bool, Any?) -> Void){
    
    initNetwork()
    var urlstr = SonarrURL()
    urlstr.append("/api")
    
    var haveID = false
    if id >= 0{
        urlstr.append("/series/\(id)")
        haveID = true
    }else{
        urlstr.append("/series")
        haveID = false
    }
    urlstr = SonarrAddAPIKEY(url: urlstr)
    
    if haveID{
        connectToService(urlString: urlstr, method: .get, postdata: nil, responseType: "Dictionary") { (isSuccess, result) in
            completion(isSuccess,result)
        }
    }else{
        connectToService(urlString: urlstr, method: .get, postdata: nil, responseType: "Array") { (isSuccess, result) in
            completion(isSuccess,result)
        }
    }
    
    
}

func SonarrGetEPList(seriesId:Int,completion: @escaping (Bool, Any?) -> Void){
    initNetwork()
    var urlstr = SonarrURL()
    urlstr.append("/api")
    
    urlstr.append("/episode")
    urlstr = SonarrAddAPIKEY(url: urlstr)
    
    urlstr.append("&seriesId=\(seriesId)")
    
    //print(urlstr)
    connectToService(urlString: urlstr, method: .get, postdata: nil, responseType: "Array") { (isSuccess, result) in
        completion(isSuccess,result)
    }
}

func SonarrGetCalendar(completion: @escaping (Bool, Any?) -> Void){
    initNetwork()
    var urlstr = SonarrURL()
    urlstr.append("/api")
    
    urlstr.append("/calendar")
    urlstr = SonarrAddAPIKEY(url: urlstr)
    
    connectToService(urlString: urlstr, method: .get, postdata: nil, responseType: "Array") { (isSuccess, result) in
        completion(isSuccess,result)
    }
}


func SonarrGetRootFolder(completion: @escaping (Bool, Any?) -> Void){
    initNetwork()
    var urlstr = SonarrURL()
    urlstr.append("/api")
    
    urlstr.append("/rootfolder")
    urlstr = SonarrAddAPIKEY(url: urlstr)
    //print(urlstr)
    connectToService(urlString: urlstr, method: .get, postdata: nil, responseType: "Array") { (isSuccess, result) in
        completion(isSuccess,result)
    }
}
