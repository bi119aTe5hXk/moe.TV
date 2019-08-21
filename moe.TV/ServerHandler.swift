//
//  ServerHandler.swift
//  moe.TV
//
//  Created by billgateshxk on 2019/08/15.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//  Doc:https://albireo.docs.apiary.io/
//
import Alamofire
import Foundation

var requestManager = Alamofire.Session.default

func getServerAddr() -> String {
    let proxyAddr = UserDefaults.standard.string(forKey: "proxy")
    let proxyPort = UserDefaults.standard.string(forKey: "proxyport")
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
    cfg.httpAdditionalHeaders = ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3864.0 Safari/537.36"]
    requestManager = Alamofire.Session(configuration: cfg)
    
    var urlStr = "https://"
    urlStr.append(UserDefaults.standard.string(forKey: "serveraddr")!)
    return urlStr
}


func logInServer(url: String, username: String, password: String, completion: @escaping (Bool, String) -> Void) {
    UserDefaults.standard.set(url, forKey: "serveraddr")
    var urlstr = getServerAddr()

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
                    UserDefaults.standard.set(true, forKey: "loggedin")
                    //print(status)
                    completion(true, (status as! String))
                }
                if let status = JSON["message"] {
                    UserDefaults.standard.set(false, forKey: "loggedin")
                    //print(status)
                    completion(false, (status as! String))
                }

            }
            break

        case .failure(let error):
            // error handling
            UserDefaults.standard.set(false, forKey: "loggedin")
            completion(false, error.localizedDescription)
            break
        }

        //completion(response.result)
    }
}

func logOutServer(completion: @escaping (Bool, String) -> Void) {
    var urlstr = getServerAddr()
    urlstr.append("/api/user/logout")
    loadCookies()
    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in

        //print(response.result)
        switch response.result {
        case .success(let value):
            if let JSON = value as? [String: Any] {
                if let status = JSON["msg"] {
                    UserDefaults.standard.set(true, forKey: "loggedin")
                    //print(status)
                    completion(true, (status as! String))
                }
                if let status = JSON["message"] {
                    UserDefaults.standard.set(false, forKey: "loggedin")
                    //print(status)
                    completion(false, (status as! String))
                }

            }
            break

        case .failure(let error):
            // error handling
            UserDefaults.standard.set(false, forKey: "loggedin")
            completion(false, error.localizedDescription)
            break
        }
    }
}


func getMyBangumiList(completion: @escaping (Bool, Any?) -> Void) {
    var urlstr = getServerAddr()
    urlstr.append("/api/home/my_bangumi?status=3")
    loadCookies()
    requestManager.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        
        //print(String(data: response.data!, encoding: .utf8) as Any)
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
            //UserDefaults.standard.set(false, forKey: "loggedin")

            completion(false, error.localizedDescription)

            break
        }
    }

}

func getOnAirList(completion: @escaping (Bool, Any?) -> Void) {
    var urlstr = getServerAddr()
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
            //UserDefaults.standard.set(false, forKey: "loggedin")
            completion(false, error.localizedDescription)

            break
        }
    }
}

func getAllBangumiList(page: Int, name: String, completion: @escaping (Bool, Any?) -> Void) {
    var urlstr = getServerAddr()
    urlstr.append("/api/home/bangumi?page=")
    urlstr.append(String(page))
    urlstr.append("&count=10&sort_field=air_date&sort_order=desc&name=")
    urlstr.append(name)
    urlstr.append("&type=-1")
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
            //UserDefaults.standard.set(false, forKey: "loggedin")
            completion(false, error.localizedDescription)

            break
        }
    }

}
func getBangumiDetail(id: String, completion: @escaping (Bool, Any?) -> Void) {
    var urlstr = getServerAddr()
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
            //UserDefaults.standard.set(false, forKey: "loggedin")
            completion(false, error.localizedDescription)

            break
        }
    }
}
func getEpisodeDetail(ep_id: String, completion: @escaping (Bool, Any?) -> Void) {
    var urlstr = getServerAddr()
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
            //UserDefaults.standard.set(false, forKey: "loggedin")
            completion(false, error.localizedDescription)
            break
        }
    }
}



func saveCookies(response: DataResponse<Any>) {
    let headerFields = response.response?.allHeaderFields as! [String: String]
    let url = response.response?.url
    let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url!)
    var cookieArray = [[HTTPCookiePropertyKey: Any]]()
    for cookie in cookies {
        cookieArray.append(cookie.properties!)
    }
    UserDefaults.standard.set(cookieArray, forKey: "savedCookies")
    UserDefaults.standard.synchronize()
}
func loadCookies() {
    guard let cookieArray = UserDefaults.standard.array(forKey: "savedCookies") as? [[HTTPCookiePropertyKey: Any]] else { return }
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
