//
//  SaveHandler.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/10.
//

import Foundation
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
    
    private let kServerAddr = "kServerAddr"
    func setServerAddr(serverInfo:String){
        keyStore.set(serverInfo, forKey: kServerAddr)
        keyStore.synchronize()
    }
    func getServerAddr() -> String {
        return keyStore.string(forKey: kServerAddr) ?? ""
    }
    
    private let kBGMTVAccessToken = "kBGMTVAccessToken"
    func setBGMTVAccessToken(token:String){
        keyStore.set(token, forKey: kBGMTVAccessToken)
        keyStore.synchronize()
    }
    func getBGMTVAccessToken() -> String {
        return keyStore.string(forKey: kBGMTVAccessToken) ?? ""
    }
    
    private let kBGMTVRefreshToken = "kBGMTVRefreshToken"
    func setBGMTVRefreshToken(token:String){
        keyStore.set(token, forKey: kBGMTVRefreshToken)
        keyStore.synchronize()
    }
    func getBGMTVRefreshToken() -> String {
        return keyStore.string(forKey: kBGMTVRefreshToken) ?? ""
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
