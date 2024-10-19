//
//  OrientationController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2024/10/08.
//
#if os(iOS)
import UIKit

class OrientationController {

	private init() {}

	static let shared = OrientationController()

	var currentOrientation: UIInterfaceOrientationMask = .portrait

	func unlockOrientation() {
		currentOrientation = .all
	}

	func lockOrientation(to orientation: UIInterfaceOrientationMask, onWindow window: UIWindow) {

		currentOrientation = orientation

		guard var topController = window.rootViewController else {
			return
		}
		while let presentedViewController = topController.presentedViewController {
			topController = presentedViewController
		}
		topController.setNeedsUpdateOfSupportedInterfaceOrientations()
	}
}
#endif
