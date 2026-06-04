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

	func attach(to playerLayer: AVPlayerLayer) {
		guard currentLayer !== playerLayer else { return }

		currentLayer = playerLayer
		controller = nil
		isPictureInPictureSupported = AVPictureInPictureController.isPictureInPictureSupported()

		guard isPictureInPictureSupported else { return }

		if let controller = AVPictureInPictureController(playerLayer: playerLayer){
			controller.delegate = self
			controller.canStartPictureInPictureAutomaticallyFromInline = true
			self.controller = controller
		}
	}

	func toggle() {
		guard let controller else { return }

		if controller.isPictureInPictureActive {
			controller.stopPictureInPicture()
		} else if controller.isPictureInPicturePossible {
			controller.startPictureInPicture()
		}
	}

	func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		isPictureInPictureActive = true
	}

	func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
		isPictureInPictureActive = false
	}
}
#endif


