//
//  ServerHandler.swift
//  moe.TV
//
//  Created by billgateshxk on 2019/08/15.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//  Doc for Albireo: https://albireo.docs.apiary.io/
//
import Foundation

private var serverAddr = ""
private let saveHandler:SaveHandler = SaveHandler()
private let jsonDecoder = JSONDecoder()
func saveCookies(response: HTTPURLResponse) {
    
    let headerFields = response.allHeaderFields as! [String: String]
    let url = response.url
    
    let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url!)
    var cookieArray = [[HTTPCookiePropertyKey: Any]]()
    for cookie in cookies {
        cookieArray.append(cookie.properties!)
    }
    saveHandler.setCookie(array: cookieArray)
    //print("cookie saved")
}
//return true if logined (have cookie result)
func loadCookies() -> Bool {
    guard let cookieArray = saveHandler.getCookie()
    else {
        print("cookie is empty")
        return false
    }
    for cookieProperties in cookieArray {
        if let cookie = HTTPCookie(properties: cookieProperties as! [HTTPCookiePropertyKey : Any]) {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
    }
    //print("cookie loaded")
    return true
}
func clearCookie(){
    saveHandler.setCookie(array: nil)
}


func initNetwork() -> String{
    //TODO: HTTP proxy support
//    var proxyConfiguration = [NSObject: AnyObject]()
//    if let proxySave:HTTPProxyItem = saveHandler.getProxy(){
//        print("GoWithProxy:",proxySave.ip as Any,":",proxySave.port as Any)
//        proxyConfiguration[kCFNetworkProxiesHTTPProxy] = proxySave.ip as AnyObject
//        proxyConfiguration[kCFNetworkProxiesHTTPPort] = proxySave.port as AnyObject
//        proxyConfiguration[kCFNetworkProxiesHTTPEnable] = 1 as AnyObject
//    }else{
//        proxyConfiguration[kCFNetworkProxiesHTTPProxy] = "" as AnyObject?
//        proxyConfiguration[kCFNetworkProxiesHTTPPort] = "" as AnyObject?
//        proxyConfiguration[kCFNetworkProxiesHTTPEnable] = 0 as AnyObject?
//    }
    
    //cfg.httpAdditionalHeaders = ["User-Agent": "bi119aTe5hXk/moe.TV/1.0 (Apple Multi-platform) (https://github.com/bi119aTe5hXk/moe.TV)"]
    
    serverAddr = saveHandler.getServerAddr()
    return serverAddr
}
func fixPathNotCompete(path:String) -> String{
    return "\(saveHandler.getServerAddr())\(path)"
}

private func postServer(urlString:String,
                postdata:Dictionary<String,Any>,
                completion: @escaping (Bool, Any) -> Void) {
    do{
        print(urlString)
        guard let url = URL(string: urlString) else {return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: postdata, options: .prettyPrinted)
        URLSession.shared.dataTask(with: request){(data, response, error) in
            if let err = error {
                completion(false, err.localizedDescription)
            }
            guard let data = data else{return}
            
            if let r = response as? HTTPURLResponse{
                saveCookies(response: r)
            }
            completion(true, data)
        }.resume()
    }catch{
        completion(false, "Cannot convert postdata to json")
    }
    
}

private func getServer(urlString:String,
               completion: @escaping (Bool, Any) -> Void) {
    guard let url = URL(string: urlString) else {return}
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    URLSession.shared.dataTask(with: request){(data, response, error) in
        if let err = error {
            completion(false, err.localizedDescription)
        }
        if let r = response as? HTTPURLResponse{
            saveCookies(response: r)
        }
        guard let data = data else{return}
        completion(true, data)
    }.resume()
    
    

}

// MARK: - Albireo Server
func loginServer(server:String,
                 username: String,
                 password: String,
                 completion: @escaping (Bool, String) -> Void) {
    saveHandler.setServerAddr(serverInfo: server)
    var urlstr = initNetwork()
    urlstr.append("/api/user/login")

    let postdata = ["name": username, "password": password, "remmember": true] as [String: Any]
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


func logOutServer(completion: @escaping (Bool, String) -> Void) {
    var urlstr = initNetwork()
    urlstr.append("/api/user/logout")
    if loadCookies(){
        getServer(urlString: urlstr) { result, data in
            if result{
                do{
                    if let JSON = try jsonDecoder.decode([String: String]?.self, from: data as! Data){
                        if let status = JSON["msg"] {
                            print(status)
                            completion(true, status)
                        }
                        if let status = JSON["message"] {
                            completion(false, status)
                        }
                        clearCookie()
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


func getMyBangumiList(completion: @escaping (Bool, Any?) -> Void) {
    var urlstr = initNetwork()
    urlstr.append("/api/home/my_bangumi?status=3")
    if loadCookies(){
        
        getServer(urlString: urlstr) { result, data in
            if result{
                do {
                    if let myBGMList:MyBangumiList = try jsonDecoder.decode(MyBangumiList?.self, from: data as! Data){
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
//    var urlstr = initNetwork()
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
//    var urlstr = initNetwork()
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
    var urlstr = initNetwork()
    urlstr.append("/api/home/bangumi/")
    urlstr.append(id)
    if loadCookies(){
        getServer(urlString: urlstr) { result, data in
            if result{
                do {
                    if let detail:BGMDetailDataModel = try jsonDecoder.decode(BGMDetailDataModel?.self, from: data as! Data){
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
    var urlstr = initNetwork()
    urlstr.append("/api/home/episode/")
    urlstr.append(ep_id)
    if loadCookies(){
        getServer(urlString: urlstr) { result, data in
            if result{
                do {
                    if let epDetail:EpisodeDetailModel = try jsonDecoder.decode(EpisodeDetailModel?.self, from: data as! Data){
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
    var urlstr = initNetwork()
    urlstr.append("/api/watch/history/")
    urlstr.append(ep_id)
    if loadCookies(){
    let postdata = ["bangumi_id": bangumi_id, "last_watch_position": last_watch_position, "percentage": percentage,"is_finished":is_finished] as [String: Any]
        
        postServer(urlString: urlstr, postdata: postdata) { result, data in
            if result{
                if let d = data as? Data{
                    let s = String(data: d, encoding: .utf8)
                    print(s)
                    completion(true, s)
                }
            }else{
                completion(false, data as! String)
            }
        }
        
    }
}


