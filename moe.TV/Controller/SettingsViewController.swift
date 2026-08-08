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
	@Published var videoCDNBackendID: String = ""
	@Published var videoCDNOptions: [VideoCDNOption] = []
	@Published var isRefreshingVideoCDNOptions = false
	@Published var videoCDNStatusMessage = ""

	init() {
		getBGMLoginStatus()
		settingsHandler.registerSettings()
		loadVideoCDNSettings()
		
		NotificationCenter.default
			.addObserver(
				self,
				selector: #selector(getBGMUserInfo),
				name: .getBGMUserInfo,
				object: nil
			)
		NotificationCenter.default
			.addObserver(
				self,
				selector: #selector(handleVideoCDNSettingsDidChange),
				name: .videoCDNSettingsDidChange,
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

	func saveVideoCDNBackendID(_ backendID: String) {
		settingsHandler.setVideoCDNBackendID(backendID)
		DispatchQueue.main.async {
			self.videoCDNBackendID = backendID
		}
	}

	func loadVideoCDNSettings() {
		videoCDNBackendID = settingsHandler.getVideoCDNBackendID()
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
					if !self.videoCDNBackendID.isEmpty,
					   !options.contains(where: { $0.id == self.videoCDNBackendID && $0.isSelectable }) {
						self.saveVideoCDNBackendID("")
						self.videoCDNStatusMessage = "Selected video CDN is unavailable. Switched to automatic CDN."
					}
				} else {
					self.videoCDNStatusMessage = "\(data)"
				}
			}
		}
	}

	private func sortedVideoCDNOptions(_ options: [VideoCDNOption]) -> [VideoCDNOption] {
		options.sorted { lhs, rhs in
			if lhs.isHealthy != rhs.isHealthy {
				return lhs.isHealthy
			}
			let lhsRegion = lhs.region ?? ""
			let rhsRegion = rhs.region ?? ""
			if lhsRegion != rhsRegion {
				return lhsRegion.localizedStandardCompare(rhsRegion) == .orderedAscending
			}
			return lhs.label.localizedStandardCompare(rhs.label) == .orderedAscending
		}
	}
}
