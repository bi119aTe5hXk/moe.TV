//
//  SettingsHandler.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import Foundation
class SettingsHandler {
	// MARK: - Keys
    private let UD_SUITE_NAME = "group.moetv"
    private let kCookie = "kCookie"
    private let kServerAddr = "kServerAddr"
    private let kBGMTVAccessToken = "kBGMTVAccessToken"
    private let kBGMTVRefreshToken = "kBGMTVRefreshToken"
    private let kBGMTVExpireTime = "kBGMTVExpireTime"

	private let kLandscapePlayback = "kLandscapePlayback"
	private let kShowBgmtvWebWhilePlaying = "kShowBgmtvWebWhilePlaying"
	private let kPlaybackRate = "kPlaybackRate"
	private let kSearchHistory = "kSearchHistory"

	private let kPlaybackHistory = "kPlaybackHistory"

    private var ud = UserDefaults() //for tvOS
    private var ub = NSUbiquitousKeyValueStore()
    
    func registerSettings(){
        ud = UserDefaults.init(suiteName: UD_SUITE_NAME) ?? UserDefaults.standard
        ub = NSUbiquitousKeyValueStore.default
           
        sync()
    }
   
    // MARK: - Albireo
    //Cookies
    func setAlbireoCookie(array: [Any]?){
        if let arr = array{
            if arr.count <= 0 {
                print("saving empty array as cookie.")
            }
            ub.set(arr, forKey: kCookie)
            sync()
        }else{
            print("cookie array nil")
        }
    }
    func getAlbireoCookie() -> Array<Any>?{
        sync()
        var arr = Array<Any>()
        arr = ub.array(forKey: kCookie) ?? []
        if arr.count > 0{
            return arr
        }
        print("getAlbireoCookie arr.count=\(arr.count), arr=\(arr)")
        return nil
    }
    //Server Address
    func setAlbireoServerAddr(serverInfo:String){
        ub.set(serverInfo, forKey: kServerAddr)
        sync()
    }
    func getAlbireoServerAddr() -> String {
        return ub.string(forKey: kServerAddr) ?? ""
    }

	//BGMTV Username
	func setBGMTVUsername(username: String){
		ub.set(username, forKey: "kBGMTVUsername")
		sync()
	}
	func getBGMTVUsername() -> String {
		return ub.string(forKey: "kBGMTVUsername") ?? ""
	}

    // MARK: - bgm.tv
	//BGMTV Access Token
    func setBGMTVAccessToken(token:String){
        ub.set(token, forKey: kBGMTVAccessToken)
        sync()
    }
    func getBGMTVAccessToken() -> String {
        return ub.string(forKey: kBGMTVAccessToken) ?? ""
    }
    
    //BGMTV Refresh Token
    func setBGMTVRefreshToken(token:String){
        ub.set(token, forKey: kBGMTVRefreshToken)
        sync()
    }
    func getBGMTVRefreshToken() -> String {
        return ub.string(forKey: kBGMTVRefreshToken) ?? ""
    }
    
    //BGMTV Expire Time
    func setBGMTVExpireTime(time:Int){
        ub.set(Int64(time), forKey: kBGMTVExpireTime)
        sync()
    }
    func getBGMTVExpireTime() -> Int {
        return Int(ub.longLong(forKey: kBGMTVExpireTime))
    }

	// MARK: - Preferences
	//Landscape playback
	func setLandscapePlayback(isEnabled: Bool){
		ub.set(isEnabled, forKey: kLandscapePlayback)
		sync()
	}
	func getLandscapePlayback() -> Bool{
		return ub.bool(forKey: kLandscapePlayback)
	}

	//Show BGM.tv while playing
	func setShowBgmtvWebWhilePlaying(isEnabled: Bool){
		ub.set(isEnabled, forKey: kShowBgmtvWebWhilePlaying)
		sync()
	}
	func getShowBgmtvWebWhilePlaying() -> Bool{
		return ub.bool(forKey: kShowBgmtvWebWhilePlaying)
	}

	//Playback Rate
	func setPlaybackRate(rate:Double) {
		ub.set(rate, forKey: kPlaybackRate)
		sync()
	}
	func getPlaybackRate() -> Double {
		if ub.double(forKey: kPlaybackRate) == 0.0 {
			return 1.0
		}else {
			return ub.double(forKey: kPlaybackRate)
		}
	}

	//Search history
	func setSearchHistory(history:Array<String>){
		ub.set(history, forKey: kSearchHistory)
		sync()
	}
	func getSearchHistory() -> Array<String>{
		return ub.array(forKey: kSearchHistory) as? Array<String> ?? []
	}

	// MARK: - Playback History
	func setPlaybackHistory(history:Array<BangumiItemModel>){
		var encodeArr = [Any]()
		history.forEach { item in
			if let encoded = try? PropertyListEncoder().encode(item) {
				encodeArr.append(encoded)
			}
		}
		print("saved \(encodeArr.count) items to history")
		ub.set(encodeArr, forKey: kPlaybackHistory)
		sync()
	}
	func getPlaybackHistory() -> Array<BangumiItemModel>{
		sync()
		if let array = ub.array(forKey: kPlaybackHistory){
			var decodeArr = [BangumiItemModel]()
			array.forEach({ item in
				if let data = item as? Data,
				   let decodeData = try? PropertyListDecoder().decode(BangumiItemModel.self, from: data) {
					decodeArr.append(decodeData)
				}
			})
			print("read \(decodeArr.count) items from history")
			if decodeArr.isEmpty{
				return []
			}
			return decodeArr
		}
		print("getPlaybackHistory error: array is empty")
		return []
	}

    // MARK: - iCloud Support
    func sync(){
        ud.synchronize()
        ub.synchronize()
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
    
    func setTopShelf(array:[BangumiItemModel]){
        registerSettings()
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
    
    func getTopShelf() -> [BangumiItemModel]?{
        registerSettings()
        let arr = ud.array(forKey: UD_TOPSHELF_ARR)
        var decodeArr = [BangumiItemModel]()
        arr?.forEach({ item in
            if let data = item as? Data,
               let decodeData = try? PropertyListDecoder().decode(BangumiItemModel.self, from: data) {
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
