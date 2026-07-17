//
//  SettingsViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/07.
//

import Foundation

class SettingsViewController: ObservableObject{
    @Published var presentLogoutAlbireoAlert = false
    @Published var presentLogoutBGMTVAlert = false
	@Published var presentClearHistoryAlert = false

	@Published var isBGMSyncEnabled:Bool = false
    @Published var isBGMUserInfoReady = false
    @Published var avatar_url = ""
    @Published var bgmUsername = ""
    @Published var bgmNickname = ""
    @Published var bgmID:Int = 0
    @Published var bgmSign = ""

	@Published var settingsHandler = SettingsHandler()

	@Published var playbackRate:Double = 1.0
	@Published var videoCDNGroup: String = ""
	@Published var videoCDNOptions: [VideoCDNOption] = []
	@Published var isRefreshingVideoCDNOptions = false
	@Published var videoCDNStatusMessage = ""
	private var isRefreshingVideoCDNLatencies = false

	init() {
		getBGMLoginStatus()
		settingsHandler.registerSettings()
		loadVideoCDNSettings()
		
		NotificationCenter.default
			.addObserver(
				self,
				selector: #selector(getBGMUserInfo),
				name: Notification.Name("getBGMUserInfo"),
				object: nil
			)
		NotificationCenter.default
			.addObserver(
				self,
				selector: #selector(handleVideoCDNSettingsDidChange),
				name: Notification.Name("videoCDNSettingsDidChange"),
				object: nil
			)
	}

    func showLogoutAlbireoAlert(){
        self.presentLogoutAlbireoAlert = true
    }
    func showLogoutBGMTVAlert(){
        self.presentLogoutBGMTVAlert = true
    }
    func setBGMInfo(avatar_url:String, bgmUsername:String, bgmNickname:String,bgmID:Int, bgmSign:String){
        DispatchQueue.main.async {
            self.avatar_url = avatar_url
            self.bgmUsername = bgmUsername
            self.bgmNickname = bgmNickname
            self.bgmID = bgmID
            self.bgmSign = bgmSign
        }
    }
    func showBGMUserInfo(){
        DispatchQueue.main.async {
            self.isBGMUserInfoReady = true
        }
    }
    
    func getAppVersion() -> String{
        if let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String{
            return v
        }else{
            return "UNKNOWN_VERSION"
        }
    }
    func getBuildVersion() -> String {
        if let v = Bundle.main.infoDictionary?["CFBundleVersion"] as? String{
            return v
        }else{
            return "UNKNOWN_BUILD"
        }
    }

	@objc func getBGMUserInfo() {
		print("getBGMUserInfo")
		getBGMTVUserInfo(completion: { result, data in
			if result{
				if let d = data as? BGMTVUserInfoModel{
					self.setBGMInfo(avatar_url: d.avatar?.large ?? "",
										  bgmUsername: d.username ?? "",
										  bgmNickname: d.nickname ?? "",
										  bgmID: d.id ?? 0,
										  bgmSign: d.sign ?? "")
					self.showBGMUserInfo()
				}
			}else{
				print("bgm.tv oauth info invalid")
				DispatchQueue.main.async {
					self.isBGMSyncEnabled = false
					self.isBGMUserInfoReady = false
				}
			}
		})
	}

	func getBGMLoginStatus(){
		if isBGMTVlogined(){
			self.isBGMSyncEnabled = true
		}else{
			self.isBGMSyncEnabled = false
		}
	}

	func saveVideoCDNGroup(_ group: String) {
		settingsHandler.setVideoCDNGroup(group)
		DispatchQueue.main.async {
			self.videoCDNGroup = group
		}
	}

	func loadVideoCDNSettings() {
		videoCDNGroup = settingsHandler.getVideoCDNGroup()
		videoCDNOptions = sortedVideoCDNOptions(settingsHandler.getVideoCDNOptions())
	}

	@objc private func handleVideoCDNSettingsDidChange() {
		loadVideoCDNSettings()
	}

	func refreshVideoCDNOptions() {
		guard !isRefreshingVideoCDNOptions else { return }
		isRefreshingVideoCDNOptions = true
		videoCDNStatusMessage = "Loading video CDN nodes..."
		refreshVideoCDNOptionsFromFirstPlayableEpisode { isSuccess, data in
			DispatchQueue.main.async {
				self.isRefreshingVideoCDNOptions = false
				if isSuccess, let options = data as? [VideoCDNOption] {
					self.videoCDNOptions = self.sortedVideoCDNOptions(options)
					self.videoCDNStatusMessage = "Video CDN nodes updated."
					if !self.videoCDNGroup.isEmpty,
					   !options.contains(where: { $0.name == self.videoCDNGroup && $0.isSelectable }) {
						self.saveVideoCDNGroup("")
						self.videoCDNStatusMessage = "Selected video CDN is unavailable. Switched to automatic CDN."
					}
				} else {
					self.videoCDNStatusMessage = "\(data)"
				}
			}
		}
	}

	func refreshVideoCDNLatencies() {
		guard !isRefreshingVideoCDNLatencies else { return }
		let currentOptions = videoCDNOptions
		guard !currentOptions.isEmpty else { return }
		isRefreshingVideoCDNLatencies = true

		updateVideoCDNOptionLatencies(currentOptions) { options in
			DispatchQueue.main.async {
				self.isRefreshingVideoCDNLatencies = false
				self.videoCDNOptions = self.sortedVideoCDNOptions(options)
			}
		}
	}

	private func sortedVideoCDNOptions(_ options: [VideoCDNOption]) -> [VideoCDNOption] {
		options.sorted { lhs, rhs in
			if lhs.isGroup != rhs.isGroup {
				return lhs.isGroup
			}

			if lhs.isGroup && rhs.isGroup {
				return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
			}

			switch (lhs.latencyMS, rhs.latencyMS) {
			case let (lhsLatency?, rhsLatency?) where lhsLatency != rhsLatency:
				return lhsLatency < rhsLatency
			case (_?, nil):
				return true
			case (nil, _?):
				return false
			default:
				if lhs.offline != rhs.offline {
					return !lhs.offline
				}
				return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
			}
		}
	}
}
