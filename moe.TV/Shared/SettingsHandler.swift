//
//  SettingsHandler.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import Foundation

extension Notification.Name {
    static let cloudSettingsDidChange = Notification.Name("cloudSettingsDidChange")
}

private final class CloudSettingsStore {
    static let shared = CloudSettingsStore()

    private let mirror = UserDefaults(suiteName: "group.moetv") ?? .standard
    private let queue = DispatchQueue(label: "moe.TV.cloudSettings", qos: .utility)
    private let writeQueue = DispatchQueue(label: "moe.TV.cloudSettingsWrites", qos: .utility)
    private let mirrorPrefix = "cloudMirror."
    private var observer: NSObjectProtocol?
    private var lastRefresh = Date.distantPast

    private init() {
        observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            let changedKeys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
            let reason = notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int
            print("Cloud settings change notification: reason=\(reason.map { String($0) } ?? "unknown"), keys=\(changedKeys?.count ?? 0)")
            self?.queue.async { [weak self] in
                self?.importCloudValues(for: changedKeys, missingOnly: false)
            }
        }

        refresh()
    }

    func refresh() {
        // Legacy installations have values only in iCloud; request them off the main thread.
        queue.async { [weak self] in
            guard let self, Date().timeIntervalSince(self.lastRefresh) >= 30 else { return }
            self.lastRefresh = Date()
            print("Cloud settings sync started")
            let succeeded = NSUbiquitousKeyValueStore.default.synchronize()
            print("Cloud settings sync finished: \(succeeded)")
            self.importCloudValues(for: nil, missingOnly: true)
        }
    }

    func set(_ value: Any, forKey key: String) {
        // Reads always use the local mirror, even if the iCloud service stalls.
        mirror.set(value, forKey: mirrorPrefix + key)
        writeQueue.async {
            NSUbiquitousKeyValueStore.default.set(value, forKey: key)
        }
    }

    func array(forKey key: String) -> [Any]? { mirror.array(forKey: mirrorPrefix + key) }
    func string(forKey key: String) -> String? { mirror.string(forKey: mirrorPrefix + key) }
    func data(forKey key: String) -> Data? { mirror.data(forKey: mirrorPrefix + key) }
    func bool(forKey key: String) -> Bool { mirror.bool(forKey: mirrorPrefix + key) }
    func double(forKey key: String) -> Double { mirror.double(forKey: mirrorPrefix + key) }
    func longLong(forKey key: String) -> Int64 { Int64(mirror.integer(forKey: mirrorPrefix + key)) }

    private func importCloudValues(for changedKeys: [String]?, missingOnly: Bool) {
        print("Cloud settings import started")
        let values = NSUbiquitousKeyValueStore.default.dictionaryRepresentation
        let keys = changedKeys ?? Array(values.keys)
        var importedCount = 0
        for key in keys {
            let localKey = mirrorPrefix + key
            if missingOnly && mirror.object(forKey: localKey) != nil { continue }
            guard let value = values[key] else { continue }
            mirror.set(value, forKey: localKey)
            importedCount += 1
        }
        print("Cloud settings import finished: available=\(values.count), imported=\(importedCount)")
        if importedCount > 0 {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .cloudSettingsDidChange, object: nil)
            }
        }
    }
}

enum AlbireoAuthMode: String {
	case legacyCookie
	case albireoV2OAuth
}

struct VideoCDNOption: Identifiable, Hashable, Codable {
	let id: String
	let label: String
	let region: String?
	let availability: String
	let selectable: Bool

	var isHealthy: Bool { availability.lowercased() == "healthy" }
	var isSelectable: Bool { selectable && isHealthy }
}

class SettingsHandler {
	static func refreshCloudSettings() {
		CloudSettingsStore.shared.refresh()
	}

	// MARK: - Keys
    private let UD_SUITE_NAME = "group.moetv"
    private let kCookie = "kCookie"
    private let kServerAddr = "kServerAddr"
    private let kBGMTVAccessToken = "kBGMTVAccessToken"
    private let kBGMTVRefreshToken = "kBGMTVRefreshToken"
    private let kBGMTVExpireTime = "kBGMTVExpireTime"
	private let kAlbireoAuthMode = "kAlbireoAuthMode"
	private let kAlbireoV2AccessToken = "kAlbireoV2AccessToken"
	private let kAlbireoV2RefreshToken = "kAlbireoV2RefreshToken"
	private let kAlbireoV2IDToken = "kAlbireoV2IDToken"
	private let kAlbireoV2ExpireTime = "kAlbireoV2ExpireTime"
	private let kAlbireoV2APIServerURL = "kAlbireoV2APIServerURL"
	private let kVideoCDNBackendID = "kVideoCDNBackendID"
	private let kVideoCDNOptions = "kVideoCDNOptions"

	private let kLandscapePlayback = "kLandscapePlayback"
	private let kShowBgmtvWebWhilePlaying = "kShowBgmtvWebWhilePlaying"
	private let kPlaybackRate = "kPlaybackRate"
	private let kUseCustomPlayerUI = "kUseCustomPlayerUI"
	private let kSearchHistory = "kSearchHistory"
	private let kSetWatchedWhenFinishedFinalEP = "kSetWatchedWhenFinishedFinalEP"

	private let kPlaybackHistory = "kPlaybackHistory"

	private let kHideUnreleaseEPs = "kHideUnreleaseEPs"
    
    private let kCheckFavStatusConflict = "kCheckFavStatusConflict"

    private var ud = UserDefaults() //for tvOS
    private let ub = CloudSettingsStore.shared

    func registerSettings(){
        ud = UserDefaults.init(suiteName: UD_SUITE_NAME) ?? UserDefaults.standard
    }
   
    // MARK: - Albireo
    //Cookies
    func setAlbireoCookie(array: [Any]?){
        if let arr = array{
            if arr.count <= 0 {
                print("saving empty array as cookie.")
            }
            ub.set(arr, forKey: kCookie)
        }else{
            print("cookie array nil")
        }
    }
    func getAlbireoCookie() -> Array<Any>?{
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
    }
    func getAlbireoServerAddr() -> String {
        return ub.string(forKey: kServerAddr) ?? ""
    }

	// MARK: - Albireo auth mode
	func setAlbireoAuthMode(_ mode: AlbireoAuthMode) {
		ub.set(mode.rawValue, forKey: kAlbireoAuthMode)
	}
	func getAlbireoAuthMode() -> AlbireoAuthMode {
		AlbireoAuthMode(rawValue: ub.string(forKey: kAlbireoAuthMode) ?? "") ?? .legacyCookie
	}

	// MARK: - Albireo V2
	func setAlbireoV2AccessToken(_ token: String) {
		ub.set(token, forKey: kAlbireoV2AccessToken)
	}
	func getAlbireoV2AccessToken() -> String {
		return ub.string(forKey: kAlbireoV2AccessToken) ?? ""
	}
	func setAlbireoV2RefreshToken(_ token: String) {
		ub.set(token, forKey: kAlbireoV2RefreshToken)
	}
	func getAlbireoV2RefreshToken() -> String {
		return ub.string(forKey: kAlbireoV2RefreshToken) ?? ""
	}
	func setAlbireoV2IDToken(_ token: String) {
		ub.set(token, forKey: kAlbireoV2IDToken)
	}
	func getAlbireoV2IDToken() -> String {
		return ub.string(forKey: kAlbireoV2IDToken) ?? ""
	}
	func setAlbireoV2ExpireTime(_ time: Int) {
		ub.set(Int64(time), forKey: kAlbireoV2ExpireTime)
	}
	func getAlbireoV2ExpireTime() -> Int {
		return Int(ub.longLong(forKey: kAlbireoV2ExpireTime))
	}
	func clearAlbireoV2AuthInfo() {
		setAlbireoV2AccessToken("")
		setAlbireoV2RefreshToken("")
		setAlbireoV2IDToken("")
		setAlbireoV2ExpireTime(0)
		if getAlbireoAuthMode() == .albireoV2OAuth {
			setAlbireoAuthMode(.legacyCookie)
		}
	}
	func setAlbireoV2APIServerURL(_ url: String) {
		ub.set(url, forKey: kAlbireoV2APIServerURL)
	}
	func getAlbireoV2APIServerURL() -> String {
		return ub.string(forKey: kAlbireoV2APIServerURL) ?? ""
	}
	func setVideoCDNBackendID(_ backendID: String) {
		ub.set(backendID, forKey: kVideoCDNBackendID)
	}
	func getVideoCDNBackendID() -> String {
		ub.string(forKey: kVideoCDNBackendID) ?? ""
	}
	func setVideoCDNOptions(_ options: [VideoCDNOption]) {
		if let data = try? JSONEncoder().encode(options) {
			ub.set(data, forKey: kVideoCDNOptions)
		}
	}
	func getVideoCDNOptions() -> [VideoCDNOption] {
		let storedData = ub.data(forKey: kVideoCDNOptions) ?? ub.data(forKey: "kAlbireoV2VideoCDNOptions")
		guard let data = storedData,
			  let options = try? JSONDecoder().decode([VideoCDNOption].self, from: data) else {
			return []
		}
		return options
	}

	//BGMTV Username
	func setBGMTVUsername(username: String){
		ub.set(username, forKey: "kBGMTVUsername")
	}
	func getBGMTVUsername() -> String {
		return ub.string(forKey: "kBGMTVUsername") ?? ""
	}

    // MARK: - bgm.tv
	//BGMTV Access Token
    func setBGMTVAccessTokenKey(token:String){
        ub.set(token, forKey: kBGMTVAccessToken)
    }
    func getBGMTVAccessTokenKey() -> String {
        return ub.string(forKey: kBGMTVAccessToken) ?? ""
    }
    
    //BGMTV Refresh Token
    func setBGMTVRefreshTokenKey(token:String){
        ub.set(token, forKey: kBGMTVRefreshToken)
    }
    func getBGMTVRefreshTokenKey() -> String {
        return ub.string(forKey: kBGMTVRefreshToken) ?? ""
    }
    
    //BGMTV Expire Time
    func setBGMTVExpireTime(time:Int){
        ub.set(Int64(time), forKey: kBGMTVExpireTime)
    }
    func getBGMTVExpireTime() -> Int {
        return Int(ub.longLong(forKey: kBGMTVExpireTime))
    }

	// MARK: - Preferences
	//Hide unrelease EPs
	func setHideUnreleaseEPs(isEnabled: Bool){
		ub.set(isEnabled, forKey: kHideUnreleaseEPs)
	}
	func getHideUnreleaseEPs() -> Bool{
		return ub.bool(forKey: kHideUnreleaseEPs)
	}

	//Set Bangumi status to watched when finished final EP
	func setSetWatchedWhenFinishedFinalEP(isEnabled: Bool){
		ub.set(isEnabled, forKey: kSetWatchedWhenFinishedFinalEP)
	}
	func getSetWatchedWhenFinishedFinalEP() -> Bool{
		return ub.bool(forKey: kSetWatchedWhenFinishedFinalEP)
	}

	//Landscape playback
	func setLandscapePlayback(isEnabled: Bool){
		ub.set(isEnabled, forKey: kLandscapePlayback)
	}
	func getLandscapePlayback() -> Bool{
		return ub.bool(forKey: kLandscapePlayback)
	}

	//Show BGM.tv while playing
	func setShowBgmtvWebWhilePlaying(isEnabled: Bool){
		ub.set(isEnabled, forKey: kShowBgmtvWebWhilePlaying)
	}
	func getShowBgmtvWebWhilePlaying() -> Bool{
		return ub.bool(forKey: kShowBgmtvWebWhilePlaying)
	}

	//Playback Rate
	func setPlaybackRate(rate:Double) {
		ub.set(rate, forKey: kPlaybackRate)
	}
	func getPlaybackRate() -> Double {
		if ub.double(forKey: kPlaybackRate) == 0.0 {
			return 1.0
		}else {
			return ub.double(forKey: kPlaybackRate)
		}
	}

	//Custom player UI
	func setUseCustomPlayerUI(isEnabled: Bool) {
		ub.set(isEnabled, forKey: kUseCustomPlayerUI)
	}
	func getUseCustomPlayerUI() -> Bool {
		return ub.bool(forKey: kUseCustomPlayerUI)
	}
    
    //Sync fav status
    func setCheckFavStatusConflict(isEnabled: Bool){
        ub.set(isEnabled, forKey: kCheckFavStatusConflict)
    }
    func getCheckFavStatusConflict() -> Bool{
        return ub.bool(forKey: kCheckFavStatusConflict)
    }
    

	//Search history
	func setSearchHistory(history:Array<String>){
		var newHistory:Array<String> = history
		if history.count > 20 {
			newHistory.removeLast(history.count - 20)
		}
		ub.set(newHistory, forKey: kSearchHistory)
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
	}
	func getPlaybackHistory() -> Array<BangumiItemModel>{
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

    // MARK: - Plist handler
    func saveToPList(key:String, data:Any) {
        if let path = getSaveFilePath(key: key){
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
