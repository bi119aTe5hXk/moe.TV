//
//  AlbireoServiceHandler.swift
//  moe.TV
//
//  Created by billgateshxk on 2020/03/13.
//  Copyright © 2020 bi119aTe5hXk. All rights reserved.
//
//  Doc for Albireo: https://albireo.docs.apiary.io/

import Foundation
import Alamofire


// MARK: - Albireo Service
func AlbireoLogInAlbireoServer(username: String,
                               password: String,
                               completion: @escaping (Bool, String) -> Void) {
    initNetwork()
    var urlstr = addPrefix(url: UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
    urlstr.append("/api/user/login")

    let postdata = ["name": username, "password": password, "remmember": true] as [String: Any]
    print(urlstr)
    
    connectToService(urlString: urlstr, method: .get, postdata: nil, responseType: "Dictionary") { (isSuccess, result) in
        if isSuccess{
            let dic = result as! Dictionary<String,Any>
            if let status = dic["msg"]  {
                UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(true, forKey: UD_LOGEDIN)
                completion(true, (status as! String))
            }
            if let status = dic["message"] {
                UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
                completion(false, (status as! String))
            }
        }else{
            completion(isSuccess,result as! String)
        }
    }
//    requestManager.request(urlstr, method: .post, parameters: postdata, encoding: JSONEncoding.default).responseJSON { response in
//        //print(String(data: response.data!, encoding: .utf8) as Any)
//        switch response.result {
//        case .success(let value):
//
//            if let JSON = value as? [String: Any] {
//                if let status = JSON["msg"] {
//                    //save cookies from response
//                    saveCookies(response: response)
//                    UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(true, forKey: UD_LOGEDIN)
//                    //print(status)
//                    completion(true, (status as! String))
//                }
//                if let status = JSON["message"] {
//                    UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
//                    //print(status)
//                    completion(false, (status as! String))
//                }
//            }
//            break
//        case .failure(let error):
//            // error handling
//            UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
//            completion(false, error.localizedDescription)
//            break
//        }
//    }
}


func AlbireoLogOutServer(completion: @escaping (Bool, String) -> Void) {
    initNetwork()
    var urlstr = addPrefix(url: (UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!))
    urlstr.append("/api/user/logout")
    loadCookies()
    
    connectToService(urlString: urlstr, method: .get, postdata: nil, responseType: "Dictionary") { (isSuccess, result) in
        if isSuccess{
            let dic = result as! Dictionary<String,Any>
            if let status = dic["msg"]  {
                UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(true, forKey: UD_LOGEDIN)
                completion(true, (status as! String))
            }
            if let status = dic["message"] {
                UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
                completion(false, (status as! String))
            }
        }else{
            completion(isSuccess,result as! String)
        }
    }
//    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
//        //print(response.result)
//        switch response.result {
//        case .success(let value):
//            if let JSON = value as? [String: Any] {
//                if let status = JSON["msg"] {
//                    UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(true, forKey: UD_LOGEDIN)
//                    //print(status)
//                    completion(true, (status as! String))
//                }
//                if let status = JSON["message"] {
//                    UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
//                    //print(status)
//                    completion(false, (status as! String))
//                }
//            }
//            break
//        case .failure(let error):
//            // error handling
//            UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
//            completion(false, error.localizedDescription)
//            break
//        }
//    }
}


func AlbireoGetSubscriptionList(completion: @escaping (Bool, Any?) -> Void) {
    initNetwork()
    var urlstr = addPrefix(url: UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
    urlstr.append("/api/home/my_bangumi?status=3")
    loadCookies()
    
    connectToService(urlString: urlstr, method: .get, postdata: nil, responseType: "Dictionary") { (isSuccess, result) in
        if isSuccess{
            let r = result as! Dictionary<String,Any>
            let data = r["data"]
            completion(isSuccess,data)
        }else{
            completion(isSuccess,result)
        }
    }
//    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
//        //print(String(data: response.data!, encoding: .utf8) as Any)
//        switch response.result {
//        case .success(let value):
//            if let JSON = value as? [String: Any] {
//                if let data = JSON["data"]{
//                    //print(data)
//                    completion(true, data)
//                }else{
//                    completion(false, "")
//                    break
//                }
//            }
//            break
//        case .failure(let error):
//            // error handling
//            //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
//            completion(false, error.localizedDescription)
//            break
//        }
//    }
}

func AlbireoGetOnAirList(completion: @escaping (Bool, Any?) -> Void) {
    initNetwork()
    var urlstr = addPrefix(url: UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
    urlstr.append("/api/home/on_air")
    loadCookies()
    
    connectToService(urlString: urlstr, method: .get, postdata: nil, responseType: "Dictionary") { (isSuccess, result) in
        if isSuccess{
            let r = result as! Dictionary<String,Any>
            let data = r["data"]
            completion(isSuccess,data)
        }else{
            completion(isSuccess,result)
        }
    }
//    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
//        //print(String(data: response.data!, encoding: .utf8) as Any)
//        //print(response.result)
//        switch response.result {
//        case .success(let value):
//            if let JSON = value as? [String: Any] {
//                let data = JSON["data"] as Any
//                //print(data)
//                completion(true, data)
//            }
//            break
//        case .failure(let error):
//            // error handling
//            //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
//            completion(false, error.localizedDescription)
//            break
//        }
//    }
}

func AlbireoGetAllBangumiList(page: Int,
                       name: String,
                       completion: @escaping (Bool, Any?) -> Void) {
    initNetwork()
    var urlstr = addPrefix(url: UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
    urlstr.append("/api/home/bangumi?page=")
    urlstr.append(String(page))
    urlstr.append("&count=12&sort_field=air_date&sort_order=desc&name=")
    urlstr.append(name)
    urlstr.append("&type=-1")
    loadCookies()
    
    connectToService(urlString: urlstr, method: .get, postdata: nil, responseType: "Dictionary") { (isSuccess, result) in
        if isSuccess{
            let r = result as! Dictionary<String,Any>
            let data = r["data"]
            completion(isSuccess,data)
        }else{
            completion(isSuccess,result)
        }
    }

//    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
//        //print(response.result)
//        switch response.result {
//        case .success(let value):
//            let dic = value as! Dictionary<String,Any>
//            print("result_count:",dic["total"] as Any)
//            if let JSON = value as? [String: Any] {
//                let data = JSON["data"] as Any
//                //print(data)
//                completion(true, data)
//            }
//            break
//        case .failure(let error):
//            // error handling
//            //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
//            completion(false, error.localizedDescription)
//            break
//        }
//    }
}
func AlbireoGetBangumiDetail(id: String,
                      completion: @escaping (Bool, Any?) -> Void) {
    initNetwork()
    var urlstr = addPrefix(url: UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
    urlstr.append("/api/home/bangumi/")
    urlstr.append(id)
    loadCookies()
    
    connectToService(urlString: urlstr, method: .get, postdata: nil, responseType: "Dictionary") { (isSuccess, result) in
        if isSuccess{
            let r = result as! Dictionary<String,Any>
            let data = r["data"]
            completion(isSuccess,data)
        }else{
            completion(isSuccess,result)
        }
    }

//    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
//        //print(response.result)
//        switch response.result {
//        case .success(let value):
//            if let JSON = value as? [String: Any] {
//                let data = JSON["data"] as Any
//                //print(data)
//                completion(true, data)
//            }
//            break
//        case .failure(let error):
//            // error handling
//            //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
//            completion(false, error.localizedDescription)
//            break
//        }
//    }
}
func AlbireoGetEpisodeDetail(ep_id: String,
                      completion: @escaping (Bool, Any?) -> Void) {
    initNetwork()
    var urlstr = addPrefix(url: UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
    urlstr.append("/api/home/episode/")
    urlstr.append(ep_id)
    loadCookies()

    connectToService(urlString: urlstr, method: .get, postdata: nil, responseType: "Dictionary") { (isSuccess, result) in
        completion(isSuccess,result)
    }
}

func AlbireoSentEPWatchProgress(ep_id: String,
                         bangumi_id:String,
                         last_watch_position:Float,
                         percentage:Double,
                         is_finished:Bool,
                         completion: @escaping (Bool, Any?) -> Void){
    initNetwork()
    var urlstr = addPrefix(url: UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
    urlstr.append("/api/watch/history/")
    urlstr.append(ep_id)
    loadCookies()
    let postdata = ["bangumi_id": bangumi_id, "last_watch_position": last_watch_position, "percentage": percentage,"is_finished":is_finished] as [String: Any]
    
    connectToService(urlString: urlstr, method: .post, postdata: postdata, responseType: "Dictionary") { (isSuccess, result) in
        completion(isSuccess,result)
    }
}
