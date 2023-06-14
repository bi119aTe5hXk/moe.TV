//
//  SaveHandler.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/10.
//

import Foundation

struct HTTPProxyItem{
    var ip:String
    var port:Int
}

class SaveHandler {
    private var keyStore = NSUbiquitousKeyValueStore()
    
    private let kCookie = "kCookie"
    func setCookie(array: Array<Any>?){
        keyStore.set(array, forKey: kCookie)
        keyStore.synchronize()
    }
    func getCookie() -> Array<Any>?{
        return keyStore.array(forKey: kCookie) ?? nil
    }
    
    private let kProxy = "kProxy"
    func setProxy(proxy:HTTPProxyItem){
        let item:Dictionary<String,Any> = ["ip":proxy.ip,"port":proxy.port]
        keyStore.set(item, forKey: kProxy)
        keyStore.synchronize()
    }
    func getProxy() -> HTTPProxyItem?{
        if let item:Dictionary<String,Any> = keyStore.dictionary(forKey: kProxy){
            return HTTPProxyItem.init(ip: item["ip"] as! String, port: item["port"] as! Int)
        }else{
            return nil
        }
    }
    
    private let kServerAddr = "kServerAddr"
    func setServerAddr(serverInfo:String){
        keyStore.set(serverInfo, forKey: kServerAddr)
        keyStore.synchronize()
    }
    func getServerAddr() -> String {
        return keyStore.string(forKey: kServerAddr) ?? ""
    }
    
}
