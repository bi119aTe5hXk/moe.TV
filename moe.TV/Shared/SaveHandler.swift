//
//  SaveHandler.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import Foundation
class SaveHandler {
    private var keyStore = NSUbiquitousKeyValueStore()
    
    private let kCookie = "kCookie"
    func setAlbireoCookie(array: Array<Any>?){
        keyStore.set(array, forKey: kCookie)
        keyStore.synchronize()
    }
    func getAlbireoCookie() -> Array<Any>?{
        keyStore.synchronize()
        if let arr = keyStore.array(forKey: kCookie){
            if arr.count > 0{
                return arr
            }
        }
        return nil
    }
    
    private let kServerAddr = "kServerAddr"
    func setAlbireoServerAddr(serverInfo:String){
        keyStore.set(serverInfo, forKey: kServerAddr)
        keyStore.synchronize()
    }
    func getAlbireoServerAddr() -> String {
        keyStore.synchronize()
        return keyStore.string(forKey: kServerAddr) ?? ""
    }
    
    private let kBGMTVAccessToken = "kBGMTVAccessToken"
    func setBGMTVAccessToken(token:String){
        keyStore.set(token, forKey: kBGMTVAccessToken)
        keyStore.synchronize()
    }
    func getBGMTVAccessToken() -> String {
        keyStore.synchronize()
        return keyStore.string(forKey: kBGMTVAccessToken) ?? ""
    }
    
    private let kBGMTVRefreshToken = "kBGMTVRefreshToken"
    func setBGMTVRefreshToken(token:String){
        keyStore.set(token, forKey: kBGMTVRefreshToken)
        keyStore.synchronize()
    }
    func getBGMTVRefreshToken() -> String {
        keyStore.synchronize()
        return keyStore.string(forKey: kBGMTVRefreshToken) ?? ""
    }
    
    private let kBGMTVExpireTime = "kBGMTVExpireTime"
    func setBGMTVExpireTime(time:Int){
        keyStore.set(time, forKey: kBGMTVExpireTime)
        keyStore.synchronize()
    }
    func getBGMTVExpireTime() -> Int {
        keyStore.synchronize()
        return Int(keyStore.longLong(forKey: kBGMTVExpireTime))
    }
    
    func saveToPList(key:String, data:Any) {
        if let path = getSaveFilePath(key: key){
            print("savekeyPath:\(path)")
            do{
                let data = try PropertyListSerialization.data(fromPropertyList: data, format: .xml, options: 0)
                try data.write(to: path)
            }catch{
                print(error)
            }
        }
    }
    func readArrayFromPList(key:String) -> [Any]? {
        if let path = getSaveFilePath(key: key){
            print("readkeyPath:\(path)")
            guard let plistData = FileManager.default.contents(atPath: path.path) else { return nil }
            guard let plist = try? PropertyListSerialization.propertyList(from: plistData, options: .mutableContainers, format:nil) as? [Any] else { return nil }
            //print(plist)
            return plist
        }else{
            print("failed to read \(key).plist")
            return nil
        }
    }
        
    func getSaveFilePath(key:String) -> URL?{
        do {
            let documentsDirectory = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return documentsDirectory.appendingPathComponent("\(key).plist")
        }catch{
            print(error)
            return nil
        }
    }
    
#if os(tvOS)
    //For tvOS TopShelf
    private let UD_SUITE_NAME = "group.moetv"
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
