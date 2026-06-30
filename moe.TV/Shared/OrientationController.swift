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

	private(set) var isManagingOrientation = false
	var currentOrientation: UIInterfaceOrientationMask = .all

	func unlockOrientation() {
		isManagingOrientation = false
		currentOrientation = .all
		requestGeometryUpdate(for: .all)
	}

	func lockOrientation(to orientation: UIInterfaceOrientationMask, onWindow window: UIWindow? = nil) {
		isManagingOrientation = true
		currentOrientation = orientation
		requestGeometryUpdate(for: orientation, onWindow: window)
	}

	func restorePortraitThenUnlock() {
		lockOrientation(to: .portrait)
		Task { @MainActor in
			try? await Task.sleep(nanoseconds: 350_000_000)
			unlockOrientation()
		}
	}

	func isLandscapeManaged() -> Bool {
		isManagingOrientation && !currentOrientation.intersection(.landscape).isEmpty
	}

	private func requestGeometryUpdate(for orientation: UIInterfaceOrientationMask, onWindow window: UIWindow? = nil) {
		let targetWindow = window ?? activeWindow()
		guard let windowScene = targetWindow?.windowScene else { return }

		if #available(iOS 16.0, *) {
			windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation)) { error in
				print("Failed to update orientation: \(error)")
			}
		} else if let interfaceOrientation = preferredInterfaceOrientation(for: orientation) {
			UIDevice.current.setValue(interfaceOrientation.rawValue, forKey: "orientation")
		}

		targetWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
	}

	private func activeWindow() -> UIWindow? {
		UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.flatMap(\.windows)
			.first { $0.isKeyWindow }
	}

	private func preferredInterfaceOrientation(for mask: UIInterfaceOrientationMask) -> UIInterfaceOrientation? {
		if mask.contains(.landscapeRight) {
			return .landscapeRight
		}
		if mask.contains(.landscapeLeft) {
			return .landscapeLeft
		}
		if mask.contains(.portrait) {
			return .portrait
		}
		return nil
	}
}
#endif
