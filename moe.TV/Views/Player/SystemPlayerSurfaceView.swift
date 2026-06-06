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
	var title: String?
	var subtitle: String?
	var onClose: (() -> Void)?

	var body: some View {
		Group {
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
		.overlay {
			#if !os(tvOS)
			AutoHidingPlayerChrome(
				playerVM: playerVM,
				title: title,
				subtitle: subtitle,
				onClose: onClose
			)
			#endif
		}
	}
}

struct CustomPlayerSurfaceView: View {
	let player: AVPlayer
	let ep: EpisodeDetailModel?
	let playerVM: PlayerViewController
	@ObservedObject var observer: PlayerItemObserver
	let onStatus: (AVPlayer.TimeControlStatus?) -> Void
	var title: String?
	var subtitle: String?
	var onClose: (() -> Void)?

	#if os(iOS) || os(tvOS)
	@State private var presentsFullscreenPlayer = false
	#endif

	#if os(iOS)
	@StateObject private var pictureInPicture = PlayerPictureInPictureController()
	#endif

	var body: some View {
		customPlayerContent
			.background(Color.black.ignoresSafeArea())
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
				ZStack(alignment: .topLeading) {
					customPlayerContent
						.background(Color.black.ignoresSafeArea())
					Button(action: {
						presentsFullscreenPlayer = false
					}, label: {
						Image(systemName: "xmark.circle.fill")
							.font(.largeTitle)
							.foregroundColor(.white)
							.shadow(radius: 4)
					})
					.buttonStyle(.plain)
					.padding(20)
				}
				.background(Color.black.ignoresSafeArea())
			}
			#endif
	}

	private var customPlayerContent: some View {
		ZStack {
			Color.black.ignoresSafeArea()
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
				},
				title: title,
				subtitle: subtitle,
				onClose: onClose
			)
			#elseif os(tvOS)
			CustomPlayerControlsView(
				playerVM: playerVM,
				onFullScreenToggle: {
					presentsFullscreenPlayer.toggle()
				}
			)
			#else
			CustomPlayerControlsView(
				playerVM: playerVM,
				title: title,
				subtitle: subtitle,
				onClose: onClose
			)
			#endif
		}
	}
}

private struct AutoHidingPlayerChrome: View {
	@ObservedObject var playerVM: PlayerViewController
	var title: String?
	var subtitle: String?
	var onClose: (() -> Void)?

	@State private var isVisible = true
	@State private var hideTask: Task<Void, Never>?

	var body: some View {
		Group {
			if isVisible && (hasTitleText || onClose != nil) {
				ZStack(alignment: .topLeading) {
					Color.black.opacity(0.24)
						.ignoresSafeArea()
						.allowsHitTesting(false)

					if let onClose {
						Button(action: onClose) {
							Image(systemName: "xmark.circle.fill")
								.font(.system(size: 30, weight: .semibold))
								.foregroundColor(.white)
								.shadow(radius: 4)
								.frame(width: 54, height: 54)
								.background(.black.opacity(0.34), in: Circle())
						}
						.buttonStyle(.plain)
						.padding(.leading, 28)
						.padding(.top, 22)
						.accessibilityLabel("Close")
					}

					if hasTitleText {
						VStack(alignment: .leading, spacing: 4) {
							if let title, !title.isEmpty {
								Text(title)
									.font(.title3.weight(.semibold))
									.lineLimit(1)
									.minimumScaleFactor(0.75)
							}

							if let subtitle, !subtitle.isEmpty {
								Text(subtitle)
									.font(.subheadline)
									.foregroundStyle(.white.opacity(0.82))
									.lineLimit(1)
									.minimumScaleFactor(0.75)
							}
						}
						.foregroundColor(.white)
						.shadow(radius: 4)
						.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
						.padding(.horizontal, 18)
						.padding(.bottom, 84)
					}
				}
				.transition(.opacity)
			}
		}
		.onAppear {
			scheduleAutoHideIfNeeded()
		}
		.onChange(of: playerVM.isPlaying) { isPlaying in
			if isPlaying {
				scheduleAutoHideIfNeeded()
			} else {
				hideTask?.cancel()
				withAnimation(.easeInOut(duration: 0.18)) {
					isVisible = true
				}
			}
		}
		.onDisappear {
			hideTask?.cancel()
		}
	}

	private func scheduleAutoHideIfNeeded() {
		hideTask?.cancel()
		withAnimation(.easeInOut(duration: 0.18)) {
			isVisible = true
		}
		guard playerVM.isPlaying else { return }
		hideTask = Task { @MainActor in
			try? await Task.sleep(nanoseconds: 5_000_000_000)
			guard !Task.isCancelled else { return }
			withAnimation(.easeInOut(duration: 0.18)) {
				isVisible = false
			}
		}
	}

	private var hasTitleText: Bool {
		(title?.isEmpty == false) || (subtitle?.isEmpty == false)
	}
}
