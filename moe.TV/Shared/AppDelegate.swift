//
//  AppDelegate.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2024/10/08.
//
#if os(iOS)
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
	private let settingsHandler = SettingsHandler()
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		return true
	}

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
		if connectingSceneSession.role == .windowApplication {
			configuration.delegateClass = SceneDelegate.self
		}
		return configuration
	}

	func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
		if UIDevice.current.userInterfaceIdiom == .phone && settingsHandler.getLandscapePlayback(){
			return OrientationController.shared.currentOrientation
		}else{
			return .all
		}
	}
}
#endif
