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

	init() {
		getBGMLoginStatus()
		
		NotificationCenter.default
			.addObserver(
				self,
				selector: #selector(getBGMUserInfo),
				name: Notification.Name("getBGMUserInfo"),
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
				logoutBGMTV()
				self.isBGMSyncEnabled = false
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
}
