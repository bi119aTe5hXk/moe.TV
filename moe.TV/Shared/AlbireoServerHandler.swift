//
//  ServerHandler.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2019/08/15.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//  Doc for Albireo: https://albireo.docs.apiary.io/
//
import Foundation

private var serverAddr = ""
private let saveHandler:SaveHandler = SaveHandler()
private let jsonDecoder = JSONDecoder()
let userAgent = "bi119aTe5hXk/moe.TV/1.0 (Apple Multi-platform) (https://github.com/bi119aTe5hXk/moe.TV)"


func saveAlbireoCookies(response: HTTPURLResponse) {
    let headerFields = response.allHeaderFields as! [String: String]
    let url = response.url
    
    let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url!)
    var cookieArray = [[HTTPCookiePropertyKey: Any]]()
    for cookie in cookies {
        cookieArray.append(cookie.properties!)
    }
    saveHandler.setAlbireoCookie(array: cookieArray)
    print("albireo cookie saved")
}

//return true if have cookie result
func loadAlbireoCookies() -> Bool {
    if let cookieArray = saveHandler.getAlbireoCookie(){
        for cookieProperties in cookieArray {
            if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any]) {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
        print("albireo cookie loaded")
        return true
    }else {
        print("albireo cookie is nil")
        return false
    }
}
func clearCookie(){
    saveHandler.setAlbireoCookie(array: [])
    print("albireo cookie cleared")
}

func isAlbireoLoginValid(completion: @escaping (Bool) -> Void){
    getAlbireoUserInfo { result, data in
        completion(result)
    }
}


func getAlbireoServer() -> String{
    serverAddr = saveHandler.getAlbireoServerAddr()
    return serverAddr
}
func fixPathNotCompete(path:String) -> String{
    return "\(saveHandler.getAlbireoServerAddr())\(path)"
}

private func postServer(urlString:String,
                postdata:Dictionary<String,Any>,
                completion: @escaping (Bool, Any) -> Void) {
    //print("connecting server via POST")
    do{
        print(urlString)
        guard let url = URL(string: urlString) else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: postdata, options: .prettyPrinted)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request){(data, response, error) in
            if let err = error {
                completion(false, err.localizedDescription)
            }
            guard let data = data else{return}
            
            if let r = response as? HTTPURLResponse{
                saveAlbireoCookies(response: r)
            }
            completion(true, data)
        }.resume()
    }catch{
        completion(false, "Cannot convert postdata to json")
    }
    
}

private func getServer(urlString:String,
               completion: @escaping (Bool, Any) -> Void) {
    //print("connecting server via GET:\(urlString)")
    guard let url = URL(string: urlString) else {return}
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
    URLSession.shared.dataTask(with: request){(data, response, error) in
        if let err = error {
            completion(false, err.localizedDescription)
        }
        if let r = response as? HTTPURLResponse{
            saveAlbireoCookies(response: r)
        }
        guard let data = data else{return}
        completion(true, data)
    }.resume()
}

// MARK: - Albireo Server APIs
func loginAlbireoServer(server:String,
                 username: String,
                 password: String,
                 completion: @escaping (Bool, String) -> Void) {
    saveHandler.setAlbireoServerAddr(serverInfo: server)
    var urlstr = getAlbireoServer()
    urlstr.append("/api/user/login")

    let postdata = ["name": username, "password": password, "remmember": true] as [String : Any]
    print(urlstr)
    
    postServer(urlString: urlstr, postdata: postdata) { result, data in
        if result{
            
            do{
                if let JSON = try jsonDecoder.decode([String: String]?.self, from: data as! Data){
                    if let status = JSON["msg"] {
                        print(status)
                        completion(true, status)
                    }
                    if let status = JSON["message"] {
                        clearCookie()
                        completion(false, status)
                    }
                }
            }catch{
                completion(false, "there is a problem with json decode")
            }
        }else{
            completion(false, data as! String)
        }
    }
    
}


func logoutAlbireoServer(completion: @escaping (Bool, String) -> Void) {
    //TODO: logout via API, get method will save cookie couse logout failed
//    var urlstr = getAlbireoServer()
//    urlstr.append("/api/user/logout")
//    getServer(urlString: urlstr) { result, data in
//        if result{
//            do{
//                if let JSON = try jsonDecoder.decode([String: String]?.self, from: data as! Data){
//                    if let status = JSON["msg"] {
//                        print(status)
//                        completion(true, status)
//                    }
//                    if let status = JSON["message"] {//logout failed?
//                        print(status)
//                        completion(false, status)
//                    }
//                }
//            }catch{
//                completion(false, "there is a problem with json decode")
//            }
//        }else{
//            completion(false, data as! String)
//        }
//    }
    clearCookie()
}

func getAlbireoUserInfo(completion: @escaping (Bool, Any?) -> Void){
    var urlstr = getAlbireoServer()
    urlstr.append("/api/user/info")
    if loadAlbireoCookies(){
        getServer(urlString: urlstr) { result, data in
            if result{
                do {
                    if let userInfo = try jsonDecoder.decode(AlbireoUserInfoData?.self, from: data as! Data){
                        completion(true, userInfo)
                    }else{
                        completion(false, data as! String)
                    }
                }catch{
                    completion(false, "there is a problem with json decode")
                }
            }else{
                completion(false, data as! String)
            }
        }
    }else{
        completion(false, "no cookies!")
    }
}


func getMyBangumiList(completion: @escaping (Bool, Any?) -> Void) {
    var urlstr = getAlbireoServer()
    urlstr.append("/api/home/my_bangumi?status=3")
    if loadAlbireoCookies(){
        getServer(urlString: urlstr) { result, data in
            if result{
                do {
                    if let myBGMList = try jsonDecoder.decode(MyBangumiList?.self, from: data as! Data){
                        completion(true, myBGMList.data)
                    }else{
                        completion(false, data as! String)
                    }
                }catch{
                    completion(false, "there is a problem with json decode")
                }
                
            }else{
                completion(false, data as! String)
            }
        }
    }
}

//func getOnAirList(completion: @escaping (Bool, Any?) -> Void) {
//    var urlstr = getAlbireoServer()
//    urlstr.append("/api/home/on_air")
//    if loadCookies(){
//        getServer(urlString: urlstr) { result, data in
//            if result{
//                if let JSON = data as? [String: Any] {
//                    let jdata = JSON["data"] as Any
//                    //print(data)
//                    completion(true, jdata)
//                }
//            }else{
//                completion(false, data as! String)
//            }
//        }
//    }
//}

//func getAllBangumiList(page: Int,
//                       name: String,
//                       completion: @escaping (Bool, Any?) -> Void) {
//    var urlstr = getAlbireoServer()
//    urlstr.append("/api/home/bangumi?page=")
//    urlstr.append(String(page))
//    urlstr.append("&count=12&sort_field=air_date&sort_order=desc&name=")
//    urlstr.append(name)
//    urlstr.append("&type=-1")
//    if loadCookies(){
//
//        getServer(urlString: urlstr) { result, data in
//            if result{
//                let dic = data as! [String: Any]
//                print("result_count:",dic["total"] as Any)
//
//                if let JSON = data as? [String: Any] {
//                    let jdata = JSON["data"] as Any
//                    //print(data)
//                    completion(true, jdata)
//                }
//            }else{
//                completion(false, data as! String)
//            }
//        }
//    }
//}
func getBangumiDetail(id: String,
                      completion: @escaping (Bool, Any?) -> Void) {
    var urlstr = getAlbireoServer()
    urlstr.append("/api/home/bangumi/")
    urlstr.append(id)
    if loadAlbireoCookies(){
        getServer(urlString: urlstr) { result, data in
            if result{
                do {
                    if let detail = try jsonDecoder.decode(BGMDetailDataModel?.self, from: data as! Data){
                        completion(true, detail.data)
                    }else{
                        completion(false, data as! String)
                    }
                }catch{
                    completion(false, "there is a problem with json decode")
                }
            }else{
                completion(false, data as! String)
            }
        }
    }
}
func getEpisodeDetail(ep_id: String,
                      completion: @escaping (Bool, Any?) -> Void) {
    var urlstr = getAlbireoServer()
    urlstr.append("/api/home/episode/")
    urlstr.append(ep_id)
    if loadAlbireoCookies(){
        getServer(urlString: urlstr) { result, data in
            if result{
                do {
                    if let epDetail = try jsonDecoder.decode(EpisodeDetailModel?.self, from: data as! Data){
                        completion(true, epDetail)
                    }else{
                        completion(false, data as! String)
                    }
                }catch{
                    print(error)
                    completion(false, "there is a problem with json decode")
                }
            }else{
                completion(false, data as! String)
            }
        }
        
    }
}

func sentEPWatchProgress(ep_id: String,
                         bangumi_id:String,
                         last_watch_position:Double,
                         percentage:Double,
                         is_finished:Bool,
                         completion: @escaping (Bool, Any?) -> Void){
    var urlstr = getAlbireoServer()
    urlstr.append("/api/watch/history/")
    urlstr.append(ep_id)
    if loadAlbireoCookies(){
    let postdata = ["bangumi_id": bangumi_id,
                    "last_watch_position": last_watch_position,
                    "percentage": percentage,
                    "is_finished":is_finished] as [String: Any]
        
        postServer(urlString: urlstr, postdata: postdata) { result, data in
            if result{
                if let d = data as? Data{
                    let s = String(data: d, encoding: .utf8)
                    completion(true, s)
                }
            }else{
                completion(false, data as! String)
            }
        }
        
    }
}


