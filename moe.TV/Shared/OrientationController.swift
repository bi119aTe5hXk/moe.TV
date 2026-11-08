//
//  OrientationController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2024/10/08.
//
#if os(iOS)
import UIKit

@MainActor
final class OrientationController {

	private init() {}

	static let shared = OrientationController()

	private(set) var isManagingOrientation = false
	var currentOrientation: UIInterfaceOrientationMask = .all
	private var requestGeneration = 0

	func unlockOrientation() {
		requestGeneration += 1
		isManagingOrientation = false
		currentOrientation = .all
		requestGeometryUpdate(for: .all)
	}

	func lockOrientation(to orientation: UIInterfaceOrientationMask, onWindow window: UIWindow? = nil) {
		requestGeneration += 1
		isManagingOrientation = true
		currentOrientation = orientation
		requestGeometryUpdate(for: orientation, onWindow: window)
	}

	func restorePortraitThenUnlock() {
		requestGeneration += 1
		let restoreGeneration = requestGeneration
		Task { @MainActor in
			try? await Task.sleep(nanoseconds: 500_000_000)
			guard restoreGeneration == requestGeneration else { return }
			isManagingOrientation = true
			currentOrientation = .portrait
			requestGeometryUpdate(for: .portrait)

			try? await Task.sleep(nanoseconds: 350_000_000)
			guard restoreGeneration == requestGeneration else { return }
			unlockOrientation()
		}
	}

	func isLandscapeManaged() -> Bool {
		isManagingOrientation && !currentOrientation.intersection(.landscape).isEmpty
	}

	func isInterfaceLandscape() -> Bool {
		activeWindow()?.windowScene?.interfaceOrientation.isLandscape == true
	}

	private func requestGeometryUpdate(for orientation: UIInterfaceOrientationMask, onWindow window: UIWindow? = nil) {
		let targetWindow = window ?? activeWindow()
		guard let windowScene = targetWindow?.windowScene else { return }
		targetWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()

		if #available(iOS 16.0, *) {
			windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation)) { error in
				print("Failed to update orientation: \(error)")
			}
		} else if let interfaceOrientation = preferredInterfaceOrientation(for: orientation) {
			UIDevice.current.setValue(interfaceOrientation.rawValue, forKey: "orientation")
		}

	}

	private func activeWindow() -> UIWindow? {
		UIApplication.shared.connectedScenes
			.compactMap { $0 as? UIWindowScene }
			.flatMap(\.windows)
				.first { $0.isKeyWindow }
			?? UIApplication.shared.connectedScenes
				.compactMap { $0 as? UIWindowScene }
				.first { $0.activationState == .foregroundActive }?
				.windows.first
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
