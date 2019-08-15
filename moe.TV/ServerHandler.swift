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
    var urlStr = "https://"
    urlStr.append(UserDefaults.standard.string(forKey: "serveraddr")!)
    urlStr.append("/api")
    return urlStr
}
func logInServer(url:String, username:String, password:String, completion: @escaping (Any?) -> Void) {
    UserDefaults.standard.set(url, forKey: "serveraddr")
    var urlstr = getServerAddr()
    
    
    urlstr.append("/user/login")
    
    let postdata = ["name":username, "password":password, "remmember":true] as [String : Any]
    print("try login...")
    AF.request(urlstr, method: .post, parameters: postdata, encoding: JSONEncoding.default).responseJSON { response in
        
        //save cookies from response
        saveCookies(response: response)
        
        
        print(response.result)
        //completion(response.result)
    }
}


func getMyBangumiList(completion: @escaping (Any?) -> Void) {
    var urlstr = getServerAddr()
    urlstr.append("/home/my_bangumi?status=3")
    loadCookies()
    AF.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        
        print(response.result)
        //completion(response.result)
    }
    
}

func getOnAirList(completion: @escaping (Any?) -> Void) {
    var urlstr = getServerAddr()
    urlstr.append("/home/on_air")
    loadCookies()
    AF.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        
        print(response.result)
        //completion(response.result)
    }
}

func getAllBangumiList(page:Int, name:String, completion: @escaping (Any?) -> Void) {
    var urlstr = getServerAddr()
    urlstr.append("/home/bangumi?page=")
    urlstr.append(String(page))
    urlstr.append("&count=10&sort_field=air_date&sort_order=desc&name=")
    urlstr.append(name)
    urlstr.append("&type=-1")
    loadCookies()
    
    AF.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        
        print(response.result)
        //completion(response.result)
    }
    
}
func getBangumiDetail(id:String, completion: @escaping (Any?) -> Void) {
    var urlstr = getServerAddr()
    urlstr.append("/home/bangumi/")
    urlstr.append(id)
    loadCookies()
    
    AF.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        
        print(response.result)
        //completion(response.result)
    }
}
func getEpisodeDetail(ep_id:String,completion: @escaping (Any?) -> Void) {
    var urlstr = getServerAddr()
    urlstr.append("/home/episode/")
    urlstr.append(ep_id)
    loadCookies()
    
    AF.request(urlstr, method: .get, encoding: JSONEncoding.default).responseJSON { response in
        
        print(response.result)
        //completion(response.result)
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
