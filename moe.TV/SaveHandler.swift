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
    
    
#if os(tvOS)
    //For tvOS TopShelf
    private let UD_SUITE_NAME = "group.moe.TV"
    private let UD_TOPSHELF_ARR = "topShelfArr"
    
    func setTopShelf(array:[MyBangumiItemModel]){
        var encodeArr = [Any]()
        array.forEach { item in
            if let encoded = try? PropertyListEncoder().encode(item) {
                encodeArr.append(encoded)
            }
        }
        print("saved \(encodeArr.count) items")
        UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(encodeArr, forKey: UD_TOPSHELF_ARR)
        UserDefaults.init(suiteName: UD_SUITE_NAME)?.synchronize()
    }
    
    func getTopShelf() -> [MyBangumiItemModel]?{
        let arr = UserDefaults.init(suiteName: UD_SUITE_NAME)!.array(forKey: UD_TOPSHELF_ARR)
        var decodeArr = [MyBangumiItemModel]()
        arr?.forEach({ item in
            if let data = item as? Data,
               let decodeData = try? PropertyListDecoder().decode(MyBangumiItemModel.self, from: data) {
                decodeArr.append(decodeData)
                    }
        })
        print("read \(decodeArr.count) items")
        if decodeArr.isEmpty{
            return nil
        }
        return decodeArr
    }
    
#endif
}
