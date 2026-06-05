//
//  AVPlayerLayerView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2026/06/04.
//

import SwiftUI
import AVKit


#if os(iOS) || os(tvOS)
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

	func attach(to playerLayer: AVPlayerLayer) {
		guard currentLayer !== playerLayer else { return }

		currentLayer = playerLayer
		controller = nil
		hasStartedPictureInPictureOnce = false
		isPictureInPictureSupported = AVPictureInPictureController.isPictureInPictureSupported()

		if isPictureInPictureSupported {
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
		primeTimelineForPictureInPicture()

		Task { @MainActor in
			let initialDelay: UInt64 = hasStartedPictureInPictureOnce ? 120_000_000 : 550_000_000
			try? await Task.sleep(nanoseconds: initialDelay)

			NowPlayingManager.shared.refreshPlaybackInfo()

			// Build the controller only after the player/Now Playing timeline has been refreshed.
			// The first controller created too early can snapshot 00:00 for the PiP timeline.
			let freshController = AVPictureInPictureController(playerLayer: currentLayer)
			freshController?.delegate = self
			freshController?.canStartPictureInPictureAutomaticallyFromInline = true
			controller = freshController

			try? await Task.sleep(nanoseconds: hasStartedPictureInPictureOnce ? 80_000_000 : 250_000_000)
			NowPlayingManager.shared.refreshPlaybackInfo()

			guard let controller,
			      !controller.isPictureInPictureActive,
			      controller.isPictureInPicturePossible else {
				isStartingPictureInPicture = false
				return
			}

			controller.startPictureInPicture()
			hasStartedPictureInPictureOnce = true
			isStartingPictureInPicture = false
		}
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


