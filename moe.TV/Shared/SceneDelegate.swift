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
	#if targetEnvironment(macCatalyst)
	private let windowWidthKey = "MacCatalystWindowWidth"
	private let windowHeightKey = "MacCatalystWindowHeight"
	private var pendingWindowSizeSave: DispatchWorkItem?
	#endif

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else { return }
		self.window = windowScene.keyWindow
		#if targetEnvironment(macCatalyst)
		restoreWindowSize(for: windowScene)
		#endif
	}

	#if targetEnvironment(macCatalyst)
	func sceneWillResignActive(_ scene: UIScene) {
		guard let windowScene = scene as? UIWindowScene else { return }
		pendingWindowSizeSave?.cancel()
		saveWindowSize(for: windowScene)
	}

	func sceneDidDisconnect(_ scene: UIScene) {
		guard let windowScene = scene as? UIWindowScene else { return }
		pendingWindowSizeSave?.cancel()
		saveWindowSize(for: windowScene)
	}

	func windowScene(
		_ windowScene: UIWindowScene,
		didUpdate previousCoordinateSpace: UICoordinateSpace,
		interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation,
		traitCollection previousTraitCollection: UITraitCollection
	) {
		pendingWindowSizeSave?.cancel()
		let saveWorkItem = DispatchWorkItem { [weak self, weak windowScene] in
			guard let self, let windowScene else { return }
			self.saveWindowSize(for: windowScene)
		}
		pendingWindowSizeSave = saveWorkItem
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: saveWorkItem)
	}

	private func saveWindowSize(for windowScene: UIWindowScene) {
		let size = windowScene.effectiveGeometry.systemFrame.size
		guard size.width > 0, size.height > 0 else { return }
		UserDefaults.standard.set(size.width, forKey: windowWidthKey)
		UserDefaults.standard.set(size.height, forKey: windowHeightKey)
	}

	private func restoreWindowSize(for windowScene: UIWindowScene) {
		let defaults = UserDefaults.standard
		let storedWidth = defaults.double(forKey: windowWidthKey)
		let storedHeight = defaults.double(forKey: windowHeightKey)
		guard storedWidth > 0, storedHeight > 0 else { return }

		DispatchQueue.main.async {
			let currentFrame = windowScene.effectiveGeometry.systemFrame
			let screenSize = windowScene.screen.bounds.size
			let minimumSize = windowScene.sizeRestrictions?.minimumSize ?? .zero
			let maximumSize = windowScene.sizeRestrictions?.maximumSize ?? screenSize
			let maximumWidth = min(maximumSize.width, screenSize.width)
			let maximumHeight = min(maximumSize.height, screenSize.height)
			let restoredSize = CGSize(
				width: min(max(storedWidth, minimumSize.width), maximumWidth),
				height: min(max(storedHeight, minimumSize.height), maximumHeight)
			)
			let frame = CGRect(origin: currentFrame.origin, size: restoredSize)
			let preferences = UIWindowScene.GeometryPreferences.Mac(systemFrame: frame)
			windowScene.requestGeometryUpdate(preferences) { error in
				print("Unable to restore Mac Catalyst window size: \(error)")
			}
		}
	}
	#endif
}
#endif
