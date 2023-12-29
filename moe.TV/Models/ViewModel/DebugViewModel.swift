//
//  DebugViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/12/30.
//

import Foundation

class DebugViewModel: ObservableObject {
    let settings = SettingsHandler()
    
    func getBGMTVAccessToken() -> String {
        return settings.getBGMTVAccessToken()
    }
    func getBGMTVRefreshToken() -> String {
        return settings.getBGMTVRefreshToken()
    }
    func getBGMExpireTime() -> Int {
        return settings.getBGMTVExpireTime()
    }
    
    func reSyncBGM(){
        saveBGMLoginInfo(accessToken: settings.getBGMTVAccessToken(),
                         refreshToken: settings.getBGMTVRefreshToken(),
                         expireIn: settings.getBGMTVExpireTime())
        settings.sync()
    }
}
