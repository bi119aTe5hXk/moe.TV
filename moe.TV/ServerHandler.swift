//
//  ServerHandler.swift
//  moe.TV
//
//  Created by billgateshxk on 2019/08/15.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import Foundation

func getServerAddr() -> String {
    return UserDefaults.standard.string(forKey: "serveraddr")!
}
func logInServer(username:String, password:String, completion: @escaping (Any?, String?) -> Void) {
    var urlstr = getServerAddr()
    urlstr.append("/api/user/login")
    
    createConnectionWithURL(urlstr, "POST", ["name":username, "password":password, "remmember":true],completion: { (responseObject, error) in
        completion(responseObject, error)
    })
}


func getMyBangumiList(completion: @escaping (Any?, String?) -> Void) {
    
}

func getOnAirList(completion: @escaping (Any?, String?) -> Void) {
    
}

func getAllBangumiList(page:Int, name:String, completion: @escaping (Any?, String?) -> Void) {
    
}
func getBangumiDetail(id:String, completion: @escaping (Any?, String?) -> Void) {
    
}
func getEpisodeDetail(ep_id:String,completion: @escaping (Any?, String?) -> Void) {
    
}
private func createConnectionWithURL(_ url: String, _ method: String, _ data: Dictionary<String, String>?, completion: @escaping (Any?, String?) -> Void) {
    var request: URLRequest? = nil
    print(url)
    switch method
    {
    case "GET":
        var components = URLComponents(string: url)!
        
        if(data != nil)
        {
            for(k, v) in data!
            {
                components.queryItems?.append(URLQueryItem(name: k, value: v))
            }
        }
        
        request = URLRequest(url: (components.url)!)
        request?.httpMethod = "GET"
        
        break
    case "POST":
        let jsonEncoder = JSONEncoder()
        
        let urlObject = URL(string: url)
        request = URLRequest(url: urlObject!)
        request?.httpMethod = "POST"
        
        do {
            let json = try jsonEncoder.encode(data)
            print(try JSONSerialization.jsonObject(with: json, options: []) as Any)
            request?.httpBody = json
        } catch { print(error) }
        
        break
    default:
        return;
    }
    
    let session = URLSession.shared.dataTask(with: request!) { (rdata, rep, err) in
        guard let data = rdata, // is there data
            let response = rep as? HTTPURLResponse, // is there HTTP response
            (200 ..< 300) ~= response.statusCode, // is statusCode 2XX
            err == nil else { // was there no error, otherwise ...
                print(err?.localizedDescription as Any)
                var errstr = ""
                if err != nil {
                    errstr = err as! String
                }else{
                    errstr = String.init(data: rdata!, encoding: .utf8)!
                }
                completion(nil, errstr)
                return
        }
        let responseObject = (try? JSONSerialization.jsonObject(with: data, options: []))
        print(responseObject as Any)
        completion(responseObject, nil)
        
        
    }
    
    session.resume()
    
}
