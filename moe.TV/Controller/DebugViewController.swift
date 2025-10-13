//
//  DebugViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/12/30.
//

import Foundation

class DebugViewController: ObservableObject {
    let settings = SettingsHandler()
	func getBGMTVUsernameDEBUG() -> String {
		return settings.getBGMTVUsername()
	}

    func getBGMTVAccessTokenDEBUG() -> String {
        return settings.getBGMTVAccessTokenKey()
    }
    func getBGMTVRefreshTokenDEBUG() -> String {
        return settings.getBGMTVRefreshTokenKey()
    }
    func getBGMExpireTimeDEBUG() -> Int {
        return settings.getBGMTVExpireTime()
    }
    
    func reSyncBGM(){
		saveBGMLoginInfo(username: settings.getBGMTVUsername(),
						 accessToken: settings.getBGMTVAccessTokenKey(),
                         refreshToken: settings.getBGMTVRefreshTokenKey(),
                         expireIn: settings.getBGMTVExpireTime())
        settings.sync()
    }
}
