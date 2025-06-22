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

    @Published var isBGMUserInfoReady = false
    @Published var avatar_url = ""
    @Published var bgmUsername = ""
    @Published var bgmNickname = ""
    @Published var bgmID:Int = 0
    @Published var bgmSign = ""

	@Published var settingsHandler = SettingsHandler()

	@Published var playbackRate:Double = 1.0

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
}
