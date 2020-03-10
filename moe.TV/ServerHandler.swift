//
//  ServerHandler.swift
//  moe.TV
//
//  Created by billgateshxk on 2019/08/15.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//  Doc for Albireo: https://albireo.docs.apiary.io/
//  Doc for Sonarr: https://github.com/Sonarr/Sonarr/wiki/API
//
import Alamofire
import Foundation

var requestManager = Alamofire.Session.default

func saveCookies(response: DataResponse<Any,AFError>) {
    let headerFields = response.response?.allHeaderFields as! [String: String]
    let url = response.response?.url
    let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url!)
    var cookieArray = [[HTTPCookiePropertyKey: Any]]()
    for cookie in cookies {
        cookieArray.append(cookie.properties!)
    }
    UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(cookieArray, forKey: UD_SAVED_COOKIES)
    UserDefaults.init(suiteName: UD_SUITE_NAME)?.synchronize()
}
func loadCookies() {
    guard let cookieArray = UserDefaults.init(suiteName: UD_SUITE_NAME)?.array(forKey: UD_SAVED_COOKIES) as? [[HTTPCookiePropertyKey: Any]] else { return }
    for cookieProperties in cookieArray {
        if let cookie = HTTPCookie(properties: cookieProperties) {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
    }
}

func cancelRequest(){
    requestManager.cancelAllRequests()
//    Alamofire.Session.default.session.getTasksWithCompletionHandler({ dataTasks, uploadTasks, downloadTasks in
//    dataTasks.forEach { $0.cancel() }
//    uploadTasks.forEach { $0.cancel() }
//    downloadTasks.forEach { $0.cancel() }
//    })
}

func initNetwork() {
    let proxyAddr = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_PROXY_SERVER)
    let proxyPort = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_PROXY_PORT)
    var proxyConfiguration = [NSObject: AnyObject]()
    
    if (proxyAddr?.lengthOfBytes(using: .utf8))! > 0 &&
        (proxyPort?.lengthOfBytes(using: .utf8))! > 0{
        print("GoWithProxy:",proxyAddr as Any,":",proxyPort as Any)
        proxyConfiguration[kCFNetworkProxiesHTTPProxy] = proxyAddr as AnyObject?
        proxyConfiguration[kCFNetworkProxiesHTTPPort] = proxyPort as AnyObject?
        proxyConfiguration[kCFNetworkProxiesHTTPEnable] = 1 as AnyObject?
    }else{
        //print("GoWithoutProxy")
        proxyConfiguration[kCFNetworkProxiesHTTPProxy] = "" as AnyObject?
        proxyConfiguration[kCFNetworkProxiesHTTPPort] = "" as AnyObject?
        proxyConfiguration[kCFNetworkProxiesHTTPEnable] = 0 as AnyObject?
    }
    
    let cfg = Alamofire.Session.default.session.configuration
    cfg.connectionProxyDictionary = proxyConfiguration
    //cfg.httpAdditionalHeaders = ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36"]
    requestManager = Alamofire.Session(configuration: cfg)
    
}
func addPrefix(url:String) -> String{
        //var url:String = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!
    //    if (!urlstr.uppercased().hasPrefix("http://".uppercased()) &&
    //        !urlstr.uppercased().hasPrefix("https://".uppercased())){
    //        print("URL \(urlstr) has no prefix fond, add https as default")
    //        urlstr = "https://" + urlstr //use https as default
    //    }
    var urlstr = url
        if UserDefaults.init(suiteName: UD_SUITE_NAME)!.bool(forKey: UD_USING_HTTPS){
            urlstr = "https://" + urlstr
        }else{
            urlstr = "http://" + urlstr
        }
    return urlstr
}



// MARK: - Albireo Server
func AlbireoLogInAlbireoServer(username: String,
                               password: String,
                               completion: @escaping (Bool, String) -> Void) {
    initNetwork()
    var urlstr = addPrefix(url: UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
    urlstr.append("/api/user/login")

    let postdata = ["name": username, "password": password, "remmember": true] as [String: Any]
    print(urlstr)
    requestManager.request(urlstr, method: .post, parameters: postdata, encoding: JSONEncoding.default).responseJSON { response in
        //print(String(data: response.data!, encoding: .utf8) as Any)
        switch response.result {
        case .success(let value):
            
            if let JSON = value as? [String: Any] {
                if let status = JSON["msg"] {
                    //save cookies from response
                    saveCookies(response: response)
                    UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(true, forKey: UD_LOGEDIN)
                    //print(status)
                    completion(true, (status as! String))
                }
                if let status = JSON["message"] {
                    UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
                    //print(status)
                    completion(false, (status as! String))
                }
            }
            break
        case .failure(let error):
            // error handling
            UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
            completion(false, error.localizedDescription)
            break
        }
    }
}


func AlbireoLogOutServer(completion: @escaping (Bool, String) -> Void) {
    initNetwork()
    var urlstr = addPrefix(url: (UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!))
    urlstr.append("/api/user/logout")
    loadCookies()
    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        //print(response.result)
        switch response.result {
        case .success(let value):
            if let JSON = value as? [String: Any] {
                if let status = JSON["msg"] {
                    UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(true, forKey: UD_LOGEDIN)
                    //print(status)
                    completion(true, (status as! String))
                }
                if let status = JSON["message"] {
                    UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
                    //print(status)
                    completion(false, (status as! String))
                }
            }
            break
        case .failure(let error):
            // error handling
            UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
            completion(false, error.localizedDescription)
            break
        }
    }
}


func AlbireoGetMyBangumiList(completion: @escaping (Bool, Any?) -> Void) {
    initNetwork()
    var urlstr = addPrefix(url: UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
    urlstr.append("/api/home/my_bangumi?status=3")
    loadCookies()
    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        //print(String(data: response.data!, encoding: .utf8) as Any)
        switch response.result {
        case .success(let value):
            if let JSON = value as? [String: Any] {
                if let data = JSON["data"]{
                    //print(data)
                    completion(true, data)
                }else{
                    completion(false, "")
                    break
                }
            }
            break
        case .failure(let error):
            // error handling
            //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
            completion(false, error.localizedDescription)
            break
        }
    }
}

func AlbireoGetOnAirList(completion: @escaping (Bool, Any?) -> Void) {
    initNetwork()
    var urlstr = addPrefix(url: UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
    urlstr.append("/api/home/on_air")
    loadCookies()
    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        //print(String(data: response.data!, encoding: .utf8) as Any)
        //print(response.result)
        switch response.result {
        case .success(let value):
            if let JSON = value as? [String: Any] {
                let data = JSON["data"] as Any
                //print(data)
                completion(true, data)
            }
            break
        case .failure(let error):
            // error handling
            //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
            completion(false, error.localizedDescription)
            break
        }
    }
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

    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        //print(response.result)
        switch response.result {
        case .success(let value):
            let dic = value as! Dictionary<String,Any>
            print("result_count:",dic["total"] as Any)
            if let JSON = value as? [String: Any] {
                let data = JSON["data"] as Any
                //print(data)
                completion(true, data)
            }
            break
        case .failure(let error):
            // error handling
            //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
            completion(false, error.localizedDescription)
            break
        }
    }
}
func AlbireoGetBangumiDetail(id: String,
                      completion: @escaping (Bool, Any?) -> Void) {
    initNetwork()
    var urlstr = addPrefix(url: UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
    urlstr.append("/api/home/bangumi/")
    urlstr.append(id)
    loadCookies()

    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        //print(response.result)
        switch response.result {
        case .success(let value):
            if let JSON = value as? [String: Any] {
                let data = JSON["data"] as Any
                //print(data)
                completion(true, data)
            }
            break
        case .failure(let error):
            // error handling
            //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
            completion(false, error.localizedDescription)
            break
        }
    }
}
func AlbireoGetEpisodeDetail(ep_id: String,
                      completion: @escaping (Bool, Any?) -> Void) {
    initNetwork()
    var urlstr = addPrefix(url: UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
    urlstr.append("/api/home/episode/")
    urlstr.append(ep_id)
    loadCookies()

    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        //print(response.result)
        switch response.result {
        case .success(let value):
            if let JSON = value as? [String: Any] {
                //print(JSON)
                completion(true, JSON)
            }
            break
        case .failure(let error):
            // error handling
            //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
            completion(false, error.localizedDescription)
            break
        }
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
    requestManager.request(urlstr, method: .post, parameters: postdata, encoding: JSONEncoding.default).responseJSON { response in
        //print(response.result)
        switch response.result {
        case .success(let value):
            if let JSON = value as? [String: Any] {
                //print(JSON)
                completion(true, JSON)
            }
            break
        case .failure(let error):
            // error handling
            //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
            completion(false, error.localizedDescription)
            break
        }
    }
}


// MARK: - Sonarr Server


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
    
    //add http basic auth info if needed
    if UserDefaults.init(suiteName: UD_SUITE_NAME)!.bool(forKey: UD_SONARR_USINGBASICAUTH) {
        let username = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SONARR_USERNAME)
        let password = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SONARR_PASSWORD)
        urlstr  = "\(username!):\(password!)@"
    }
    
    //append host name and port
    urlstr.append(UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
    
    //add http/https prefix
    urlstr = addPrefix(url: urlstr)
    
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
    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        //print(response)
        switch response.result {
        case .success(let value):
            if let JSON = value as? [String: Any] {
                //print(JSON)
                completion(true, JSON)
            }
            break
        case .failure(let error):
            // error handling
            //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
            completion(false, error.localizedDescription)
            break
        }
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
    
    //print(urlstr)
    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        //print(response)
        switch response.result {
        case .success(let value):
            if haveID{
                if let JSON = value as? [String:Any] {
                    //print(JSON)
                    completion(true, JSON)
                }
            }else{
                if let JSON = value as? [Any] {
                    print(JSON)
                    completion(true, JSON)
                }
            }
            
            break
        case .failure(let error):
            // error handling
            //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
            completion(false, error.localizedDescription)
            break
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
    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        //print(response)
        switch response.result {
        case .success(let value):
            if let JSON = value as? [Any] {
                //print(JSON)
                completion(true, JSON)
            }
            break
        case .failure(let error):
            // error handling
            //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
            completion(false, error.localizedDescription)
            break
        }
    }
}

func SonarrGetCalendar(completion: @escaping (Bool, Any?) -> Void){
    initNetwork()
    var urlstr = SonarrURL()
    urlstr.append("/api")
    
    urlstr.append("/calendar")
    urlstr = SonarrAddAPIKEY(url: urlstr)
    
    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        //print(response.result)
        switch response.result {
        case .success(let value):
            if let JSON = value as? [Any] {
               // print(JSON)
                completion(true, JSON)
            }
            break
        case .failure(let error):
            // error handling
            //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
            completion(false, error.localizedDescription)
            break
        }
    }
}


func SonarrGetRootFolder(completion: @escaping (Bool, Any?) -> Void){
    initNetwork()
    var urlstr = SonarrURL()
    urlstr.append("/api")
    
    urlstr.append("/rootfolder")
    urlstr = SonarrAddAPIKEY(url: urlstr)
    //print(urlstr)
    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        //print(response.result)
        switch response.result {
        case .success(let value):
            if let JSON = value as? [Any] {
                //print(JSON)
                completion(true, JSON)
            }
            break
        case .failure(let error):
            // error handling
            //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
            completion(false, error.localizedDescription)
            break
        }
    }
}
