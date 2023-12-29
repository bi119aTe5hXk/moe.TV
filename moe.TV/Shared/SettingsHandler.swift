//
//  SettingsHandler.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import Foundation
class SettingsHandler {
    //private var keyStore = NSUbiquitousKeyValueStore()//TODO: support for non-iCloud account/devices
    private var settingList = [String: Any]()
    
    func registerSettings(){
        addListenerToNSUbiquitousKeyValueStore()
    }
    
    //Cookies
    private let kCookie = "kCookie"
    func setAlbireoCookie(array: [Any]?){
        saveValue(value: array, key: kCookie)
    }
    func getAlbireoCookie() -> Array<Any>?{
        if let arr = getArrayValue(key: kCookie){
            if arr.count > 0{
                return arr
            }
        }
        return nil
    }
    
    //Server Address
    private let kServerAddr = "kServerAddr"
    func setAlbireoServerAddr(serverInfo:String){
        saveValue(value: serverInfo, key: kServerAddr)
    }
    func getAlbireoServerAddr() -> String {
        return getStringValue(key: kServerAddr) ?? ""
    }
    
    //BGMTV Access Token
    private let kBGMTVAccessToken = "kBGMTVAccessToken"
    func setBGMTVAccessToken(token:String){
        saveValue(value: token, key: kBGMTVAccessToken)
    }
    func getBGMTVAccessToken() -> String {
        return getStringValue(key: kBGMTVAccessToken) ?? ""
    }
    
    //BGMTV Refresh Token
    private let kBGMTVRefreshToken = "kBGMTVRefreshToken"
    func setBGMTVRefreshToken(token:String){
        saveValue(value: token, key: kBGMTVRefreshToken)
    }
    func getBGMTVRefreshToken() -> String {
        return getStringValue(key: kBGMTVRefreshToken) ?? ""
    }
    
    //BGMTV Expire Time
    private let kBGMTVExpireTime = "kBGMTVExpireTime"
    func setBGMTVExpireTime(time:Int){
        saveValue(value: time, key: kBGMTVExpireTime)
    }
    func getBGMTVExpireTime() -> Int {
        return getIntValue(key: kBGMTVExpireTime) ?? 0
    }
    
    // MARK: - iCloud Support
    func saveValue(value:Any?, key:String){
        UserDefaults.standard.set(value, forKey: key)
        NSUbiquitousKeyValueStore.default.set(value, forKey: key)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    private func getArrayValue(key:String) -> [Any]?{
        return UserDefaults.standard.array(forKey: key)
    }
    private func getStringValue(key:String) -> String?{
        return UserDefaults.standard.string(forKey: key)
    }
    private func getIntValue(key:String) -> Int?{
        return UserDefaults.standard.integer(forKey: key)
    }
    
    
    //Add a listener to NSUbiquitousKeyValueStore for sync Settings to iCloud
    func addListenerToNSUbiquitousKeyValueStore() {
        /** Listen for key-value store changes from iCloud.
            This notification is posted when the value of one or more keys in the local
            key-value store changed due to incoming data pushed from iCloud.
        */
        NotificationCenter.default.addObserver(self,
            selector: #selector(ubiquitousKeyValueStoreDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default)
        /** Note: By passing the default key-value store object as "object" it tells iCloud that
            this is the object whose notifications you want to receive.
        */
        // Get any KVStore change since last launch.
        
        /** This will spark the notification "NSUbiquitousKeyValueStoreDidChangeExternallyNotification",
            to ourselves to listen for iCloud KVStore changes.
        
            It is important to only do this step *after* registering for notifications,
            this prevents a notification arriving before code is ready to respond to it.
        */
        if NSUbiquitousKeyValueStore.default.synchronize() == false {
            fatalError("This app was not built with the proper entitlement requests.")
        }
    }
    /** This notification is sent only upon a change received from iCloud; it is not sent when your app
        sets a value. So this is called when the key-value store in the cloud has changed externally.
         The old  value is replaced with the new one. Additionally, NSUserDefaults is updated as well.
    */
    @objc
    func ubiquitousKeyValueStoreDidChange(_ notification: Notification) {
        /** We get more information from the notification, by using:
            NSUbiquitousKeyValueStoreChangeReasonKey or NSUbiquitousKeyValueStoreChangedKeysKey
            constants on the notification's useInfo.
         */
        guard let userInfo = notification.userInfo else { return }
        // Get the reason for the notification (initial download, external change or quota violation change).
        guard let reasonForChange = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else { return }
        /** Reasons can be:
            NSUbiquitousKeyValueStoreServerChange:
            Value(s) were changed externally from other users/devices.
            Get the changes and update the corresponding keys locally.
         
            NSUbiquitousKeyValueStoreInitialSyncChange:
            Initial downloads happen the first time a device is connected to an iCloud account,
            and when a user switches their primary iCloud account.
            Get the changes and update the corresponding keys locally.

            Do the merge with our local user defaults.
            But for this sample we have only one value, so a merge is not necessary here.

            Note: If you receive "NSUbiquitousKeyValueStoreInitialSyncChange" as the reason,
            you can decide to "merge" your local values with the server values.

            NSUbiquitousKeyValueStoreQuotaViolationChange:
            Your app’s key-value store has exceeded its space quota on the iCloud server of 1mb.

            NSUbiquitousKeyValueStoreAccountChange:
            The user has changed the primary iCloud account.
            The keys and values in the local key-value store have been replaced with those from the new account,
            regardless of the relative timestamps.
         */
        
        
        
        // Check if any of the keys we care about were updated, and if so use the new value stored under that key.
        guard let keys =
            userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }
        guard 
            keys.contains(kCookie) ||
            keys.contains(kServerAddr) ||
            keys.contains(kBGMTVAccessToken) ||
            keys.contains(kBGMTVRefreshToken) ||
            keys.contains(kBGMTVExpireTime)
        else {
            print("keys notfound")
            return
        }
        
        if reasonForChange == NSUbiquitousKeyValueStoreAccountChange{
            // User changed account, so fall back to use UserDefaults
            
        }
        
        /** Replace the local value with the value from the cloud, but *only* if it's a value we know how to interpret.
            It is important to validate any value that comes in through iCloud, because it could have been generated
            by a different version of your app.
         */
//        let possibleKVFromiCloud = NSUbiquitousKeyValueStore.default.
        
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
