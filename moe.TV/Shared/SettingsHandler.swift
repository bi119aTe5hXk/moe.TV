//
//  SettingsHandler.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import Foundation

enum AlbireoAuthMode: String {
	case legacyCookie
	case albireoV2OAuth
}

struct VideoCDNOption: Identifiable, Hashable, Codable {
	let name: String
	let url: String?
	let servers: [String]?
	let offline: Bool
	let check: Bool?
	let lastOnline: String?
	let count: Int?
	let type: String?
	var latencyMS: Int?

	var id: String { name }
	var isGroup: Bool { servers?.isEmpty == false }
	var isSelectable: Bool { isGroup || !offline }

	enum CodingKeys: String, CodingKey {
		case name = "Name"
		case url = "URL"
		case servers = "Servers"
		case offline = "Offline"
		case check = "Check"
		case lastOnline = "LastOnline"
		case count = "Count"
		case type = "Type"
		case latencyMS
	}

	init(name: String,
		 url: String?,
		 servers: [String]?,
		 offline: Bool,
		 check: Bool?,
		 lastOnline: String?,
		 count: Int?,
		 type: String?,
		 latencyMS: Int? = nil) {
		self.name = name
		self.url = url
		self.servers = servers
		self.offline = offline
		self.check = check
		self.lastOnline = lastOnline
		self.count = count
		self.type = type
		self.latencyMS = latencyMS
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		name = try container.decode(String.self, forKey: .name)
		url = try container.decodeIfPresent(String.self, forKey: .url)
		servers = try container.decodeIfPresent([String].self, forKey: .servers)
		offline = try container.decodeIfPresent(Bool.self, forKey: .offline) ?? false
		check = try container.decodeIfPresent(Bool.self, forKey: .check)
		lastOnline = try container.decodeIfPresent(String.self, forKey: .lastOnline)
		count = try container.decodeIfPresent(Int.self, forKey: .count)
		type = try container.decodeIfPresent(String.self, forKey: .type)
		latencyMS = try container.decodeIfPresent(Int.self, forKey: .latencyMS)
	}
}

class SettingsHandler {
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
	private let kAlbireoV2AuthorizationServerURL = "kAlbireoV2AuthorizationServerURL"
	private let kAlbireoV2APIServerURL = "kAlbireoV2APIServerURL"
	private let kAlbireoV2ClientID = "kAlbireoV2ClientID"
	private let kAlbireoV2RedirectHost = "kAlbireoV2RedirectHost"
	private let kVideoCDNGroup = "kVideoCDNGroup"
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

	// MARK: - Albireo auth mode
	func setAlbireoAuthMode(_ mode: AlbireoAuthMode) {
		ub.set(mode.rawValue, forKey: kAlbireoAuthMode)
		sync()
	}
	func getAlbireoAuthMode() -> AlbireoAuthMode {
		AlbireoAuthMode(rawValue: ub.string(forKey: kAlbireoAuthMode) ?? "") ?? .legacyCookie
	}

	// MARK: - Albireo V2
	func setAlbireoV2AccessToken(_ token: String) {
		ub.set(token, forKey: kAlbireoV2AccessToken)
		sync()
	}
	func getAlbireoV2AccessToken() -> String {
		return ub.string(forKey: kAlbireoV2AccessToken) ?? ""
	}
	func setAlbireoV2RefreshToken(_ token: String) {
		ub.set(token, forKey: kAlbireoV2RefreshToken)
		sync()
	}
	func getAlbireoV2RefreshToken() -> String {
		return ub.string(forKey: kAlbireoV2RefreshToken) ?? ""
	}
	func setAlbireoV2IDToken(_ token: String) {
		ub.set(token, forKey: kAlbireoV2IDToken)
		sync()
	}
	func getAlbireoV2IDToken() -> String {
		return ub.string(forKey: kAlbireoV2IDToken) ?? ""
	}
	func setAlbireoV2ExpireTime(_ time: Int) {
		ub.set(Int64(time), forKey: kAlbireoV2ExpireTime)
		sync()
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
	func setAlbireoV2AuthorizationServerURL(_ url: String) {
		ub.set(url, forKey: kAlbireoV2AuthorizationServerURL)
		sync()
	}
	func getAlbireoV2AuthorizationServerURL() -> String {
		return ub.string(forKey: kAlbireoV2AuthorizationServerURL) ?? ""
	}
	func setAlbireoV2APIServerURL(_ url: String) {
		ub.set(url, forKey: kAlbireoV2APIServerURL)
		sync()
	}
	func getAlbireoV2APIServerURL() -> String {
		return ub.string(forKey: kAlbireoV2APIServerURL) ?? ""
	}
	func setAlbireoV2ClientID(_ clientID: String) {
		ub.set(clientID, forKey: kAlbireoV2ClientID)
		sync()
	}
	func getAlbireoV2ClientID() -> String {
		return ub.string(forKey: kAlbireoV2ClientID) ?? ""
	}
	func setAlbireoV2RedirectHost(_ host: String) {
		ub.set(host, forKey: kAlbireoV2RedirectHost)
		sync()
	}
	func getAlbireoV2RedirectHost() -> String {
		return ub.string(forKey: kAlbireoV2RedirectHost) ?? ""
	}
	func setVideoCDNGroup(_ group: String) {
		ub.set(group, forKey: kVideoCDNGroup)
		sync()
	}
	func getVideoCDNGroup() -> String {
		if let group = ub.string(forKey: kVideoCDNGroup), !group.isEmpty {
			return group
		}
		return ub.string(forKey: "kAlbireoV2VideoCDNGroup") ?? ""
	}
	func setVideoCDNOptions(_ options: [VideoCDNOption]) {
		if let data = try? JSONEncoder().encode(options) {
			ub.set(data, forKey: kVideoCDNOptions)
			sync()
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
		sync()
	}
	func getBGMTVUsername() -> String {
		return ub.string(forKey: "kBGMTVUsername") ?? ""
	}

    // MARK: - bgm.tv
	//BGMTV Access Token
    func setBGMTVAccessTokenKey(token:String){
        ub.set(token, forKey: kBGMTVAccessToken)
        sync()
    }
    func getBGMTVAccessTokenKey() -> String {
        return ub.string(forKey: kBGMTVAccessToken) ?? ""
    }
    
    //BGMTV Refresh Token
    func setBGMTVRefreshTokenKey(token:String){
        ub.set(token, forKey: kBGMTVRefreshToken)
        sync()
    }
    func getBGMTVRefreshTokenKey() -> String {
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
	//Hide unrelease EPs
	func setHideUnreleaseEPs(isEnabled: Bool){
		ub.set(isEnabled, forKey: kHideUnreleaseEPs)
		sync()
	}
	func getHideUnreleaseEPs() -> Bool{
		return ub.bool(forKey: kHideUnreleaseEPs)
	}

	//Set Bangumi status to watched when finished final EP
	func setSetWatchedWhenFinishedFinalEP(isEnabled: Bool){
		ub.set(isEnabled, forKey: kSetWatchedWhenFinishedFinalEP)
		sync()
	}
	func getSetWatchedWhenFinishedFinalEP() -> Bool{
		return ub.bool(forKey: kSetWatchedWhenFinishedFinalEP)
	}

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

	//Custom player UI
	func setUseCustomPlayerUI(isEnabled: Bool) {
		ub.set(isEnabled, forKey: kUseCustomPlayerUI)
		sync()
	}
	func getUseCustomPlayerUI() -> Bool {
		return ub.bool(forKey: kUseCustomPlayerUI)
	}
    
    //Sync fav status
    func setCheckFavStatusConflict(isEnabled: Bool){
        ub.set(isEnabled, forKey: kCheckFavStatusConflict)
        sync()
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
