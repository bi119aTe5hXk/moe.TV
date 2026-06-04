//
//  SystemPlayerSurfaceView.swift
//  moe.TV
//
//  Existing system-player surface extracted from PlayerSurfaceView.
//

import AVFoundation
import AVKit
import Combine
import SwiftUI

struct SystemPlayerSurfaceView: View {
	let player: AVPlayer
	let ep: EpisodeDetailModel?
	let playerVM: PlayerViewController
	@ObservedObject var observer: PlayerItemObserver
	let onStatus: (AVPlayer.TimeControlStatus?) -> Void

	var body: some View {
		#if os(iOS) || os(tvOS)
		VideoPlayerViewiOS(player: player, playerVM: playerVM, ep: ep)
			.persistentSystemOverlays(.hidden)
			.onReceive(observer.$currentStatus, perform: onStatus)
			.onAppear {
				observer.observe(player)
				NowPlayingManager.shared.start(player: player, ep: ep)
			}
			.onDisappear {
				NowPlayingManager.shared.stop()
			}
		#else
		VideoPlayer(player: player)
			.onReceive(observer.$currentStatus, perform: onStatus)
			.onAppear {
				observer.observe(player)
				NowPlayingManager.shared.start(player: player, ep: ep)
			}
			.onDisappear {
				NowPlayingManager.shared.stop()
			}
		#endif
	}
}

struct CustomPlayerSurfaceView: View {
	let player: AVPlayer
	let ep: EpisodeDetailModel?
	let playerVM: PlayerViewController
	@ObservedObject var observer: PlayerItemObserver
	let onStatus: (AVPlayer.TimeControlStatus?) -> Void

	#if os(iOS) || os(tvOS)
	@State private var presentsFullscreenPlayer = false
	#endif

	#if os(iOS)
	@StateObject private var pictureInPicture = PlayerPictureInPictureController()
	#endif

	var body: some View {
		customPlayerContent
			.persistentSystemOverlays(.hidden)
			.onReceive(observer.$currentStatus, perform: onStatus)
			.onAppear {
				observer.observe(player)
				NowPlayingManager.shared.start(player: player, ep: ep)
			}
			.onDisappear {
				NowPlayingManager.shared.stop()
			}
			#if os(iOS) || os(tvOS)
			.fullScreenCover(isPresented: $presentsFullscreenPlayer) {
				customPlayerContent
					.background(Color.black.ignoresSafeArea())
			}
			#endif
	}

	private var customPlayerContent: some View {
		ZStack {
			#if os(iOS)
			AVPlayerLayerView(player: player) { layer in
				pictureInPicture.attach(to: layer)
			}
			.ignoresSafeArea()
			#else
			AVPlayerLayerView(player: player)
				.ignoresSafeArea()
			#endif

			#if os(iOS)
			CustomPlayerControlsView(
				playerVM: playerVM,
				isPictureInPictureSupported: pictureInPicture.isPictureInPictureSupported,
				isPictureInPictureActive: pictureInPicture.isPictureInPictureActive,
				onPictureInPictureToggle: {
					pictureInPicture.toggle()
				},
				onFullScreenToggle: {
					presentsFullscreenPlayer.toggle()
				}
			)
			#elseif os(tvOS)
			CustomPlayerControlsView(
				playerVM: playerVM,
				onFullScreenToggle: {
					presentsFullscreenPlayer.toggle()
				}
			)
			#else
			CustomPlayerControlsView(playerVM: playerVM)
			#endif
		}
	}
}

