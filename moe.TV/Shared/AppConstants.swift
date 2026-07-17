//
//  AppConstants.swift
//  moe.TV
//

import Foundation

enum AppConstants {
	static let userAgent = "bi119aTe5hXk/moe.TV/1.0 (Apple Multi-platform) (https://github.com/bi119aTe5hXk/moe.TV)"
}

extension Notification.Name {
	static let getBGMUserInfo = Notification.Name("getBGMUserInfo")
	static let getAlbireoV2UserInfo = Notification.Name("getAlbireoV2UserInfo")
	static let videoCDNSettingsDidChange = Notification.Name("videoCDNSettingsDidChange")
}
