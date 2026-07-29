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

	func getAlbireoAuthModeDEBUG() -> String {
		settings.getAlbireoAuthMode().rawValue
	}

	func getAlbireoV2OIDCIssuerDEBUG() -> String {
		"https://authorization.box.moe"
	}

	func getAlbireoV2OIDCDiscoveryURLDEBUG() -> String {
		"https://authorization.box.moe/.well-known/openid-configuration"
	}

	func getAlbireoV2APIServerURLDEBUG() -> String {
		settings.getAlbireoV2APIServerURL()
	}

	func getAlbireoV2AccessTokenDEBUG() -> String {
		settings.getAlbireoV2AccessToken()
	}

	func getAlbireoV2RefreshTokenDEBUG() -> String {
		settings.getAlbireoV2RefreshToken()
	}

	func getAlbireoV2IDTokenDEBUG() -> String {
		settings.getAlbireoV2IDToken()
	}

	func getAlbireoV2ExpireTimeDEBUG() -> Int {
		settings.getAlbireoV2ExpireTime()
	}
    
    func reSyncBGM(){
		saveBGMLoginInfo(username: settings.getBGMTVUsername(),
						 accessToken: settings.getBGMTVAccessTokenKey(),
                         refreshToken: settings.getBGMTVRefreshTokenKey(),
                         expireIn: settings.getBGMTVExpireTime())
        settings.sync()
    }
}
