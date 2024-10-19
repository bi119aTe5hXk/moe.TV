//
//  SceneDelegate.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2024/10/08.
//
#if os(iOS)
import UIKit

class SceneDelegate: NSObject, ObservableObject, UIWindowSceneDelegate {
	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else { return }
		self.window = windowScene.keyWindow
	}
}
#endif
