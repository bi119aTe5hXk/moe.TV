//
//  ServerHandler.swift
//  moe.TV
//
//  Created by billgateshxk on 2019/08/15.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//  Doc for Albireo: https://albireo.docs.apiary.io/
//
import Alamofire
import Foundation

private var requestManager = Alamofire.Session.default
private var serverAddr = ""
private let saveHandler:SaveHandler = SaveHandler()

func saveCookies(response: DataResponse<Any,AFError>) {
    let headerFields = response.response?.allHeaderFields as! [String: String]
    let url = response.response?.url
    let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url!)
    var cookieArray = [[HTTPCookiePropertyKey: Any]]()
    for cookie in cookies {
        cookieArray.append(cookie.properties!)
    }
    saveHandler.setCookie(array: cookieArray)
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
    return true
}
func clearCookie(){
    saveHandler.setCookie(array: nil)
}

func cancelRequest(){
    requestManager.cancelAllRequests()
//    Alamofire.Session.default.session.getTasksWithCompletionHandler({ dataTasks, uploadTasks, downloadTasks in
//    dataTasks.forEach { $0.cancel() }
//    uploadTasks.forEach { $0.cancel() }
//    downloadTasks.forEach { $0.cancel() }
//    })
}

func initNetwork() -> String{
    var proxyConfiguration = [NSObject: AnyObject]()
    if let proxySave:HTTPProxyItem = saveHandler.getProxy(){
        print("GoWithProxy:",proxySave.ip as Any,":",proxySave.port as Any)
        proxyConfiguration[kCFNetworkProxiesHTTPProxy] = proxySave.ip as AnyObject
        proxyConfiguration[kCFNetworkProxiesHTTPPort] = proxySave.port as AnyObject
        proxyConfiguration[kCFNetworkProxiesHTTPEnable] = 1 as AnyObject
    }else{
        proxyConfiguration[kCFNetworkProxiesHTTPProxy] = "" as AnyObject?
        proxyConfiguration[kCFNetworkProxiesHTTPPort] = "" as AnyObject?
        proxyConfiguration[kCFNetworkProxiesHTTPEnable] = 0 as AnyObject?
    }
    
    let cfg = Alamofire.Session.default.session.configuration
    cfg.connectionProxyDictionary = proxyConfiguration
    //cfg.httpAdditionalHeaders = ["User-Agent": "bi119aTe5hXk/moe.TV/1.0 (Apple Multi-platform) (https://github.com/bi119aTe5hXk/moe.TV)"]
    requestManager = Alamofire.Session(configuration: cfg)
    serverAddr = saveHandler.getServerAddr()
    return serverAddr
}

private func postServer(url:String,
                postdata:Dictionary<String,Any>,
                completion: @escaping (Bool, Any) -> Void) {
    requestManager.request(url, method: .post, parameters: postdata, encoding: JSONEncoding.default).responseJSON { response in
        switch response.result {
        case .success(let value):
            //save cookies from response
            saveCookies(response: response)
            completion(true, value)
            break
        case .failure(let error):
            // error handling
            completion(false, error.localizedDescription)
            break
        }
    }
}

private func getServer(url:String,
               completion: @escaping (Bool, Any) -> Void) {
    requestManager.request(url, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        //print(response.result)
        switch response.result {
        case .success(let value):
            completion(true,value)
            break
        case .failure(let error):
            // error handling
            completion(false, error.localizedDescription)
            break
        }
    }
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
    
    postServer(url: urlstr, postdata: postdata) { result, data in
        if result{
            if let JSON = data as? [String: Any] {
                if let status = JSON["msg"] {
                    //print(status)
                    completion(true, status as! String)
                }
                if let status = JSON["message"] {
                    clearCookie()
                    completion(false, status as! String)
                }
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
        getServer(url: urlstr) { result, data in
            if result{
                if let JSON = data as? [String: Any] {
                    if let status = JSON["msg"] {
                        //print(status)
                        completion(true, status as! String)
                    }
                    if let status = JSON["message"] {
                        //print(status)
                        completion(false, status as! String)
                    }
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
        
        getServer(url: urlstr) { result, data in
            if result{
                if let JSON = data as? [String: Any] {
                    if let jdata = JSON["data"] as? [Any]{
                        //print(data)
                        var myBGMList = [MyBangumiItemModel]()
                        jdata.forEach { item  in
                            if let dicItem = item as? [String: Any]{
                                let myBGMItem = MyBangumiItemModel.init(id: dicItem["id"] as! String,
                                                                   bgm_id: dicItem["bgm_id"] as! Int,
                                                                   name: dicItem["name"] as! String,
                                                                   name_cn: dicItem["name_cn"] as? String,
                                                                   summary: dicItem["summary"] as? String,
                                                                   cover_image_url: dicItem["image"] as? String,
                                                                   type: dicItem["type"] as! Int,
                                                                   status: dicItem["status"] as! Int,
                                                                   air_weekday: dicItem["air_weekday"] as! Int,
                                                                   eps: dicItem["eps"] as! Int,
                                                                   favorite_status: dicItem["favorite_status"] as! Int,
                                                                   unwatched_count: dicItem["unwatched_count"] as? Int)
                                myBGMList.append(myBGMItem)
                            }else{
                                print("Item is not Dictionary:\(item)")
                            }
                        }
                        completion(true, myBGMList)
                    }else{
                        clearCookie()
                        completion(false, "")
                    }
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
//        getServer(url: urlstr) { result, data in
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

func getAllBangumiList(page: Int,
                       name: String,
                       completion: @escaping (Bool, Any?) -> Void) {
    var urlstr = initNetwork()
    urlstr.append("/api/home/bangumi?page=")
    urlstr.append(String(page))
    urlstr.append("&count=12&sort_field=air_date&sort_order=desc&name=")
    urlstr.append(name)
    urlstr.append("&type=-1")
    if loadCookies(){
        
        getServer(url: urlstr) { result, data in
            if result{
                let dic = data as! [String: Any]
                print("result_count:",dic["total"] as Any)
                
                if let JSON = data as? [String: Any] {
                    let jdata = JSON["data"] as Any
                    //print(data)
                    completion(true, jdata)
                }
            }else{
                completion(false, data as! String)
            }
        }
    }
}
func getBangumiDetail(id: String,
                      completion: @escaping (Bool, Any?) -> Void) {
    var urlstr = initNetwork()
    urlstr.append("/api/home/bangumi/")
    urlstr.append(id)
    if loadCookies(){
        getServer(url: urlstr) { result, data in
            if result{
                if let JSON = data as? [String: Any] {
                    //print(data)
                    if let jdata = JSON["data"] as? [String: Any]{
                        let jdata_eps = jdata["episodes"] as? [Any]
                        var eps = [BGMEpisode]()
                        jdata_eps?.forEach({ item in
                            if let ep = item as? [String: Any]{
                                
                                var wpd:watchProgress?
                                if let wp = ep["watch_progress"] as? [String:Any]{
                                    wpd = watchProgress(
                                        id: wp["id"] as! String,
                                        user_id: wp["user_id"] as! String,
                                        last_watch_position: (wp["last_watch_position"] as? NSNumber)!.doubleValue,
                                        bangumi_id: wp["bangumi_id"] as! String,
                                        watch_status: wp["watch_status"] as! Int,
                                        episode_id: wp["episode_id"] as! String,
                                        percentage: (wp["percentage"] as? NSNumber)!.floatValue
                                    )
                                }
                                
                                
                                
                                eps.append(
                                    BGMEpisode(
                                    id: ep["id"] as! String,
                                    bangumi_id: ep["bangumi_id"] as! String,
                                    bgm_eps_id: ep["bgm_eps_id"] as! Int,
                                    name: ep["name"] as! String,
                                    name_cn: ep["name_cn"] as? String,
                                    thumbnail: serverAddr + (ep["thumbnail"] as! String),
                                    status: ep["status"] as! Int,
                                    episode_no: ep["episode_no"] as! Int,
                                    duration: ep["duration"] as! String,
                                    watch_progress: wpd ?? nil)
                                )
                                
                            }
                        })
                        
                        let bgmItem = BangumiDetailModel(
                            id: jdata["id"] as! String,
                            bgm_id: jdata["bgm_id"] as! Int,
                            name: jdata["name"] as! String,
                            name_cn: jdata["name_cn"] as? String,
                            summary: jdata["summary"] as? String,
                            cover_image_url: jdata["image"] as? String,
                            type: jdata["type"] as! Int,
                            status: jdata["status"] as! Int,
                            air_weekday: jdata["air_weekday"] as! Int,
                            eps: jdata["eps"] as! Int,
                            episodes: eps)
                        completion(true, bgmItem)
                    }else{
                        completion(false, data as! String)
                    }
                    //completion(true, jdata)
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
        getServer(url: urlstr) { result, data in
            if result{
                if let json = data as? [String: Any] {
                    //print(JSON)
                    if let videoFiles = json["video_files"] as? [Any]{
                        var vfiles = [videoFilesListModel]()
                        videoFiles.forEach { file in
                            if let vfile = file as? [String:Any]{
                                vfiles.append(videoFilesListModel(
                                    id: vfile["id"] as! String,
                                    status: vfile["status"] as! Int,
                                    url: (serverAddr + (vfile["url"] as! String)).addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed)!,
                                    file_path: vfile["file_path"] as! String,
                                    file_name: vfile["file_name"] as? String,
                                    episode_id: vfile["episode_id"] as! String,
                                    bangumi_id: vfile["bangumi_id"] as! String,
                                    duration: vfile["duration"] as! Int))
                            }
                        }
                        
                        let epDetail = EpisodeDetailModel(
                            id: json["id"] as! String,
                            bangumi_id: json["bangumi_id"] as! String,
                            bgm_eps_id: json["bgm_eps_id"] as! Int,
                            name: json["name"] as! String,
                            name_cn:json["name_cn"] as? String,
                            summary: json["summary"] as? String,
                            thumbnail: serverAddr + (json["thumbnail"] as! String),
                            status: json["status"] as! Int,
                            episode_no: json["episode_no"] as! Int,
                            duration: json["duration"] as! String,
                            video_files: vfiles)
                        completion(true, epDetail)
                    }else{
                        print("video files is empty?!")
                    }
                    
                    //completion(true, JSON)
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
        
        postServer(url: urlstr, postdata: postdata) { result, data in
            if result{
                if let JSON = data as? [String: Any] {
                    //print(JSON)
                    completion(true, JSON)
                }
            }else{
                completion(false, data as! String)
            }
        }
        
    }
}


