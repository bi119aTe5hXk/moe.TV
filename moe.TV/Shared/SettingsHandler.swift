//
//  SettingsHandler.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import Foundation
class SettingsHandler {
    private let UD_SUITE_NAME = "group.moetv"
    private let kCookie = "kCookie"
    private let kServerAddr = "kServerAddr"
    private let kBGMTVAccessToken = "kBGMTVAccessToken"
    private let kBGMTVRefreshToken = "kBGMTVRefreshToken"
    private let kBGMTVExpireTime = "kBGMTVExpireTime"
    
    private var ud = UserDefaults()
    private var ub = NSUbiquitousKeyValueStore()
    private var isiCloudAvailable = false
    
    func registerSettings(){
        ud = UserDefaults.init(suiteName: UD_SUITE_NAME) ?? UserDefaults.standard
        
        
        if FileManager.default.ubiquityIdentityToken != nil {
            print("iCloud Available")
            ub = NSUbiquitousKeyValueStore.init()
            isiCloudAvailable = true
        } else {
            print("iCloud Unavailable")
            isiCloudAvailable = false
        }
        
        ud.register(defaults: [kCookie:[]])
        ud.register(defaults: [kServerAddr:""])
        ud.register(defaults: [kBGMTVAccessToken:""])
        ud.register(defaults: [kBGMTVRefreshToken:""])
        ud.register(defaults: [kBGMTVExpireTime:""])
        if isiCloudAvailable{
            addListenerToNSUbiquitousKeyValueStore()
        }
    }
   
    
    //Cookies
    func setAlbireoCookie(array: [[HTTPCookiePropertyKey : Any]]?){
        if let arr = array{
            if arr.count <= 0{
                print("cookie array empty")
                return
            }
            ud.setValue(arr, forKey: kCookie)
            if isiCloudAvailable == true{
                ub.set(arr, forKey: kCookie)
            }
            sync()
        }else{
            print("cookie array nil")
        }
    }
    func getAlbireoCookie() -> Array<Any>?{
        if let arr = ud.array(forKey: kCookie){
            if arr.count > 0{
                return arr
            }
            print("getAlbireoCookie arr=0")
            return nil
        }
        return nil
    }
    //Server Address
    func setAlbireoServerAddr(serverInfo:String){
        ud.setValue(serverInfo, forKey: kServerAddr)
        if isiCloudAvailable{
            ub.set(serverInfo, forKey: kServerAddr)
        }
        sync()
    }
    func getAlbireoServerAddr() -> String {
        return ud.string(forKey: kServerAddr) ?? ""
    }
    
    //BGMTV Access Token
    func setBGMTVAccessToken(token:String){
        ud.setValue(token, forKey: kBGMTVAccessToken)
        if isiCloudAvailable{
            ub.set(token, forKey: kBGMTVAccessToken)
        }
        sync()
    }
    func getBGMTVAccessToken() -> String {
        return ud.string(forKey: kBGMTVAccessToken) ?? ""
    }
    
    //BGMTV Refresh Token
    func setBGMTVRefreshToken(token:String){
        ud.setValue(token, forKey: kBGMTVRefreshToken)
        if isiCloudAvailable{
            ub.set(token, forKey: kBGMTVRefreshToken)
        }
        sync()
    }
    func getBGMTVRefreshToken() -> String {
        return ud.string(forKey: kBGMTVRefreshToken) ?? ""
    }
    
    //BGMTV Expire Time
    func setBGMTVExpireTime(time:Int){
        ud.setValue(time, forKey: kBGMTVExpireTime)
        if isiCloudAvailable{
            ub.set(time, forKey: kBGMTVExpireTime)
        }
        sync()
    }
    func getBGMTVExpireTime() -> Int {
        return ud.integer(forKey: kBGMTVExpireTime)
    }
    
    // MARK: - iCloud Support
    private func sync(){
        ud.synchronize()
        if isiCloudAvailable{
            ub.synchronize()
        }
    }
    
    //Add a listener to NSUbiquitousKeyValueStore for sync Settings to iCloud
    func addListenerToNSUbiquitousKeyValueStore() {
        NotificationCenter.default.addObserver(self,
            selector: #selector(ubiquitousKeyValueStoreDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default)
        if NSUbiquitousKeyValueStore.default.synchronize() == false {
            fatalError("This app was not built with the proper entitlement requests.")
        }
    }
    
    @objc
    func ubiquitousKeyValueStoreDidChange(_ notification: Notification) {
        
        guard let userInfo = notification.userInfo else { return }
        // Get the reason for the notification (initial download, external change or quota violation change).
        guard let reasonForChange = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else { return }
        
        // Check if any of the keys we care about were updated, and if so use the new value stored under that key.
        guard let keys =
            userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }
        guard keys.contains(kCookie) ||
        keys.contains(kServerAddr) ||
        keys.contains(kBGMTVExpireTime) ||
        keys.contains(kBGMTVAccessToken) ||
        keys.contains(kBGMTVRefreshToken)
        else {
            print("keys not found in iCloud")
            return
        }
        
        if reasonForChange == NSUbiquitousKeyValueStoreAccountChange{
            // User changed account, so fall back to use UserDefaults
        }
        
        //overwrite settings
        let possibleCookieFromiCloud = ub.array(forKey: kCookie)
        if let cookies = possibleCookieFromiCloud as? [[HTTPCookiePropertyKey : Any]]{
            ud.set(cookies, forKey: kCookie)
        }
        
        let possibleServerAddressFromiCloud = ub.string(forKey: kServerAddr)
        if let addr = possibleServerAddressFromiCloud{
            if addr.lengthOfBytes(using: .utf8) > 0{
                ud.set(addr, forKey: kServerAddr)
            }
        }
        
        let possibleBGMAccessTokenFromiCloud = ub.string(forKey: kBGMTVAccessToken)
        if let token = possibleBGMAccessTokenFromiCloud{
            if token.lengthOfBytes(using: .utf8) > 0{
                ud.set(token, forKey: kBGMTVAccessToken)
            }
        }
        
        let possibleBGMRefreshTokenFromiCloud = ub.string(forKey: kBGMTVRefreshToken)
        if let token = possibleBGMRefreshTokenFromiCloud{
            if token.lengthOfBytes(using: .utf8) > 0{
                ud.set(token, forKey: kBGMTVRefreshToken)
            }
        }
        
        let possibleBGMExpireTimeFromiCloud = ub.string(forKey: kBGMTVExpireTime)
        if let time = possibleBGMExpireTimeFromiCloud{
            ud.set(time, forKey: kBGMTVExpireTime)
        }
        
    }
    
    // MARK: - Plist handler
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
    // MARK: - tvOS TopShelf handler
#if os(tvOS)
    private let UD_TOPSHELF_ARR = "topShelfArr"
    
    func setTopShelf(array:[MyBangumiItemModel]){
        var encodeArr = [Any]()
        array.forEach { item in
            if let encoded = try? PropertyListEncoder().encode(item) {
                encodeArr.append(encoded)
            }
        }
        print("saved \(encodeArr.count) items")
        ud.set(encodeArr, forKey: UD_TOPSHELF_ARR)
        ud.synchronize()
    }
    
    func getTopShelf() -> [MyBangumiItemModel]?{
        let arr = ud.array(forKey: UD_TOPSHELF_ARR)
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
