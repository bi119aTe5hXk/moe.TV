//
//  AVPlayerLayerView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2026/06/04.
//

import SwiftUI
import AVKit


#if os(iOS) || os(tvOS) || os(visionOS)
struct AVPlayerLayerView: UIViewRepresentable {
	let player: AVPlayer
	var onLayerReady: ((AVPlayerLayer) -> Void)?

	func makeUIView(context: Context) -> PlayerLayerUIView {
		let view = PlayerLayerUIView()
		view.playerLayer.player = player
		view.playerLayer.videoGravity = .resizeAspect
		DispatchQueue.main.async {
			onLayerReady?(view.playerLayer)
		}
		return view
	}

	func updateUIView(_ uiView: PlayerLayerUIView, context: Context) {
		uiView.playerLayer.player = player
		DispatchQueue.main.async {
			onLayerReady?(uiView.playerLayer)
		}
	}
}

final class PlayerLayerUIView: UIView {
	override static var layerClass: AnyClass {
		AVPlayerLayer.self
	}

	var playerLayer: AVPlayerLayer {
		layer as! AVPlayerLayer
	}
}

#elseif os(macOS)
struct AVPlayerLayerView: NSViewRepresentable {
	let player: AVPlayer

	func makeNSView(context: Context) -> PlayerLayerNSView {
		let view = PlayerLayerNSView()
		view.playerLayer.player = player
		view.playerLayer.videoGravity = .resizeAspect
		return view
	}

	func updateNSView(_ nsView: PlayerLayerNSView, context: Context) {
		nsView.playerLayer.player = player
	}
}

final class PlayerLayerNSView: NSView {
	let playerLayer = AVPlayerLayer()

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		wantsLayer = true
		layer = playerLayer
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		wantsLayer = true
		layer = playerLayer
	}
}
#endif


#if os(iOS)
@MainActor
final class PlayerPictureInPictureController: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
	@Published private(set) var isPictureInPictureSupported = false
	@Published private(set) var isPictureInPictureActive = false

	private weak var currentLayer: AVPlayerLayer?
	private var controller: AVPictureInPictureController?
	private var hasStartedPictureInPictureOnce = false
	private var isStartingPictureInPicture = false
	private var startRetryCount = 0

	func attach(to playerLayer: AVPlayerLayer) {
		guard currentLayer !== playerLayer else { return }

		currentLayer = playerLayer
		controller = nil
		hasStartedPictureInPictureOnce = false
		startRetryCount = 0
		isPictureInPictureSupported = AVPictureInPictureController.isPictureInPictureSupported()

		if isPictureInPictureSupported {
			controller = makePictureInPictureController(for: playerLayer)
			primeTimelineForPictureInPicture()
		}
	}

	func toggle() {
		if controller?.isPictureInPictureActive == true {
			NowPlayingManager.shared.refreshPlaybackInfo()
			controller?.stopPictureInPicture()
			return
		}

		startPictureInPictureAfterPriming()
	}

	private func startPictureInPictureAfterPriming() {
		guard !isStartingPictureInPicture,
		      isPictureInPictureSupported,
		      let currentLayer else { return }

		isStartingPictureInPicture = true
		startRetryCount = 0
		primeTimelineForPictureInPicture()

		Task { @MainActor in
			try? await Task.sleep(nanoseconds: hasStartedPictureInPictureOnce ? 120_000_000 : 550_000_000)
			startPictureInPictureIfPossible()
		}
	}

	private func makePictureInPictureController(for playerLayer: AVPlayerLayer) -> AVPictureInPictureController? {
		let controller = AVPictureInPictureController(playerLayer: playerLayer)
		controller?.delegate = self
		controller?.canStartPictureInPictureAutomaticallyFromInline = true
		return controller
	}

	private func startPictureInPictureIfPossible() {
		guard let currentLayer else {
			isStartingPictureInPicture = false
			return
		}

		NowPlayingManager.shared.refreshPlaybackInfo()

		if controller == nil {
			controller = makePictureInPictureController(for: currentLayer)
		}

		guard let controller else {
			isStartingPictureInPicture = false
			print("PiP failed to start: AVPictureInPictureController could not be created")
			return
		}

		guard !controller.isPictureInPictureActive else {
			isStartingPictureInPicture = false
			return
		}

		guard controller.isPictureInPicturePossible else {
			if startRetryCount < 8 {
				startRetryCount += 1
				Task { @MainActor in
					try? await Task.sleep(nanoseconds: 250_000_000)
					startPictureInPictureIfPossible()
				}
			} else {
				isStartingPictureInPicture = false
				print("PiP failed to start: isPictureInPicturePossible is false")
			}
			return
		}

		controller.startPictureInPicture()
		hasStartedPictureInPictureOnce = true
		isStartingPictureInPicture = false
	}

	private func primeTimelineForPictureInPicture() {
		NowPlayingManager.shared.refreshPlaybackInfo()
		Task { @MainActor in
			try? await Task.sleep(nanoseconds: 150_000_000)
			NowPlayingManager.shared.refreshPlaybackInfo()
		}
	}

	func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		NowPlayingManager.shared.refreshPlaybackInfo()
		isPictureInPictureActive = true
	}

	func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		NowPlayingManager.shared.refreshPlaybackInfo()
		isStartingPictureInPicture = false
	}

	func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
		isStartingPictureInPicture = false
		print("PiP failed to start: \(error)")
	}

	func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		isPictureInPictureActive = false
		NowPlayingManager.shared.refreshPlaybackInfo()
	}
}
#endif

