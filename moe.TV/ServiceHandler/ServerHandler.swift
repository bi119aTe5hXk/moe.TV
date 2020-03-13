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
    var proxyConfiguration = [NSObject: AnyObject]()
    
    if UserDefaults.init(suiteName: UD_SUITE_NAME)!.bool(forKey: UD_PROXY_ENABLED) {
        let proxyAddr = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_PROXY_SERVER)
        let proxyPort = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_PROXY_PORT)
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
    }
    
    let cfg = Alamofire.Session.default.session.configuration
    cfg.connectionProxyDictionary = proxyConfiguration
    //cfg.httpAdditionalHeaders = ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36"]
    requestManager = Alamofire.Session(configuration: cfg)
    
}

func addPrefix(url:String) -> String{
        //var url:String = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!
//        if (!urlstr.uppercased().hasPrefix("http://".uppercased()) &&
//            !urlstr.uppercased().hasPrefix("https://".uppercased())){
//            print("URL \(urlstr) has no prefix fond, add https as default")
//            urlstr = "https://" + urlstr //use https as default
//        }
    var urlstr = url
        if UserDefaults.init(suiteName: UD_SUITE_NAME)!.bool(forKey: UD_USING_HTTPS){
            urlstr = "https://" + urlstr
        }else{
            urlstr = "http://" + urlstr
        }
    return urlstr
}
func addBasicAuth(url:String) -> String{
    var urlstr = url
    if UserDefaults.init(suiteName: UD_SUITE_NAME)!.bool(forKey: UD_SONARR_USINGBASICAUTH) {
        let username = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SONARR_USERNAME)
        let password = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SONARR_PASSWORD)
        //urlstr  = "\(username!):\(password!)@"
        urlstr.append("\(username!):\(password!)@")
    }
    return urlstr
}



func connectToService(urlString:String, method:HTTPMethod, postdata:Dictionary<String,Any>?, responseType:String, completion: @escaping (Bool, Any?) -> Void){
    requestManager.request(urlString, method: method, parameters: postdata, encoding: JSONEncoding.default).responseJSON { response in
        //print(response.result)
        switch response.result {
        case .success(let value):
            
            if responseType == "Array" {
                if let JSON = value as? [Any] {
                    //print(JSON)
                    completion(true, JSON)
                }
            }else if responseType == "Dictionary"{
                if let JSON = value as? [String:Any] {
                    //print(JSON)
                    completion(true, JSON)
                }
            }else{
                print("unknow response type")
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
