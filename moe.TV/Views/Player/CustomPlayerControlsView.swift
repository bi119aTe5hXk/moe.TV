//
//  CustomPlayerControlsView.swift
//  moe.TV
//
//  First-pass custom playback controls with cached-range visualization.
//

import AVFoundation
import SwiftUI

struct CustomPlayerControlsView: View {
	@ObservedObject var playerVM: PlayerViewController
	var isPictureInPictureSupported = false
	var isPictureInPictureActive = false
	var onPictureInPictureToggle: (() -> Void)?
	var onFullScreenToggle: (() -> Void)?

	@State private var isControlsVisible = true
	@State private var scrubTime: Double = 0
	@State private var isScrubbing = false
	@State private var hideControlsTask: Task<Void, Never>?

	var body: some View {
		ZStack {
			Color.clear
				.contentShape(Rectangle())
				.onTapGesture(count: 2) {
					playerVM.togglePlayPause()
					showControlsTemporarily()
				}
				.onTapGesture {
					if isControlsVisible {
						hideControlsTask?.cancel()
						withAnimation(.easeInOut(duration: 0.18)) {
							isControlsVisible = false
						}
					} else {
						scheduleControlsAutoHide()
					}
				}

			if isControlsVisible {
				VStack(spacing: 0) {
					topBar
					Spacer()
					centerButton
					Spacer()
					bottomControls
				}
				.transition(.opacity)
			}
		}
		.overlay(keyboardShortcuts)
		.foregroundStyle(.white)
		.onChange(of: playerVM.currentTime) { newValue in
			if !isScrubbing {
				scrubTime = newValue
			}
		}
		.onAppear {
			scrubTime = playerVM.currentTime
			scheduleControlsAutoHide()
		}
		.onChange(of: playerVM.isPlaying) { isPlaying in
			if isPlaying {
				scheduleControlsAutoHide()
			} else {
				hideControlsTask?.cancel()
				withAnimation(.easeInOut(duration: 0.18)) {
					isControlsVisible = true
				}
			}
		}
		.onDisappear {
			hideControlsTask?.cancel()
		}
	}

	private var topBar: some View {
		HStack {
			Spacer()

			if playerVM.streamingCacheManager?.state.isPrefetching == true {
				HStack(spacing: 6) {
					ProgressView()
						.progressViewStyle(.circular)
						.tint(.white)
						.scaleEffect(0.72)
					Text("Buffering")
						.font(.caption)
				}
				.padding(.horizontal, 10)
				.padding(.vertical, 6)
				.background(.black.opacity(0.42), in: Capsule())
			}
		}
		.padding(.horizontal, 18)
		.padding(.top, 14)
	}

	private var centerButton: some View {
		Button {
			playerVM.togglePlayPause()
			showControlsTemporarily()
		} label: {
			Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
				.font(.system(size: 34, weight: .semibold))
				.frame(width: 76, height: 76)
				.background(.black.opacity(0.42), in: Circle())
		}
		.buttonStyle(.plain)
		.accessibilityLabel(playerVM.isPlaying ? "Pause" : "Play")
	}

	private var bottomControls: some View {
		VStack(spacing: 10) {
			CachedProgressBar(
				currentTime: isScrubbing ? scrubTime : playerVM.currentTime,
				duration: playerVM.duration,
				loadedTimeRanges: playerVM.loadedTimeRanges,
				onSeek: { seconds in
					scrubTime = seconds
					isScrubbing = true
				},
				onSeekEnded: { seconds in
					isScrubbing = false
					playerVM.seek(to: seconds, autoPlay: playerVM.isPlaying)
					showControlsTemporarily()
				}
			)
			.frame(height: 28)

			HStack(spacing: 12) {
				Button {
					playerVM.seek(by: -15, autoPlay: playerVM.isPlaying)
					showControlsTemporarily()
				} label: {
					Image(systemName: "gobackward.15")
						.font(.system(size: 22, weight: .medium))
						.frame(width: 44, height: 38)
				}
				.buttonStyle(.plain)
				.accessibilityLabel("Back 15 seconds")

				Button {
					playerVM.togglePlayPause()
					showControlsTemporarily()
				} label: {
					Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
						.font(.system(size: 22, weight: .semibold))
						.frame(width: 44, height: 38)
				}
				.buttonStyle(.plain)
				.accessibilityLabel(playerVM.isPlaying ? "Pause" : "Play")

				Button {
					playerVM.seek(by: 15, autoPlay: playerVM.isPlaying)
					showControlsTemporarily()
				} label: {
					Image(systemName: "goforward.15")
						.font(.system(size: 22, weight: .medium))
						.frame(width: 44, height: 38)
				}
				.buttonStyle(.plain)
				.accessibilityLabel("Forward 15 seconds")

				Text(timeText)
					.font(.system(.caption, design: .monospaced))
					.lineLimit(1)
					.minimumScaleFactor(0.75)

				Spacer()

				Menu {
					ForEach(playbackRateOptions, id: \.self) { rate in
						Button {
							playerVM.setPlaybackRate(rate)
							showControlsTemporarily()
						} label: {
							if abs(playerVM.playbackRate - rate) < 0.001 {
								Label(rateText(rate), systemImage: "checkmark")
							} else {
								Text(rateText(rate))
							}
						}
					}
				} label: {
					Text(rateText(playerVM.playbackRate))
						.font(.system(.caption, design: .rounded).weight(.semibold))
						.frame(minWidth: 48, minHeight: 32)
						.padding(.horizontal, 8)
						.background(.white.opacity(0.16), in: Capsule())
				}
				.buttonStyle(.plain)
				.accessibilityLabel("Playback speed")

				if isPictureInPictureSupported, let onPictureInPictureToggle {
					Button {
						onPictureInPictureToggle()
						showControlsTemporarily()
					} label: {
						Image(systemName: isPictureInPictureActive ? "pip.exit" : "pip.enter")
							.font(.system(size: 19, weight: .medium))
							.frame(width: 44, height: 38)
					}
					.buttonStyle(.plain)
					.accessibilityLabel("Picture in Picture")
				}

				if let onFullScreenToggle {
					Button {
						onFullScreenToggle()
						showControlsTemporarily()
					} label: {
						Image(systemName: "arrow.up.left.and.arrow.down.right")
							.font(.system(size: 19, weight: .medium))
							.frame(width: 44, height: 38)
					}
					.buttonStyle(.plain)
					.accessibilityLabel("Full Screen")
				}
			}
		}
		.padding(.horizontal, 18)
		.padding(.top, 12)
		.padding(.bottom, 16)
		.background(
			LinearGradient(
				colors: [.clear, .black.opacity(0.58), .black.opacity(0.78)],
				startPoint: .top,
				endPoint: .bottom
			)
			.ignoresSafeArea(edges: .bottom)
		)
	}

	private var timeText: String {
		"\(formatTime(isScrubbing ? scrubTime : playerVM.currentTime)) / \(formatTime(playerVM.duration))"
	}

	private var keyboardShortcuts: some View {
		Group {
			Button("Play/Pause") {
				playerVM.togglePlayPause()
				showControlsTemporarily()
			}
			.keyboardShortcut(.space, modifiers: [])

			Button("Backward 15 seconds") {
				playerVM.seek(by: -15, autoPlay: playerVM.isPlaying)
				showControlsTemporarily()
			}
			.keyboardShortcut(.leftArrow, modifiers: [])

			Button("Forward 15 seconds") {
				playerVM.seek(by: 15, autoPlay: playerVM.isPlaying)
				showControlsTemporarily()
			}
			.keyboardShortcut(.rightArrow, modifiers: [])
		}
		.frame(width: 0, height: 0)
		.opacity(0)
		.accessibilityHidden(true)
	}

	private var playbackRateOptions: [Double] {
		[0.5, 1.0, 1.25, 1.5, 2.0]
	}

	private func showControlsTemporarily() {
		scheduleControlsAutoHide()
	}

	private func scheduleControlsAutoHide() {
		hideControlsTask?.cancel()

		withAnimation(.easeInOut(duration: 0.18)) {
			isControlsVisible = true
		}

		guard playerVM.isPlaying else { return }

		hideControlsTask = Task { @MainActor in
			try? await Task.sleep(nanoseconds: 5_000_000_000)
			if !Task.isCancelled, playerVM.isPlaying, !isScrubbing {
				withAnimation(.easeInOut(duration: 0.18)) {
					isControlsVisible = false
				}
			}
		}
	}

	private func formatTime(_ seconds: Double) -> String {
		guard seconds.isFinite, seconds >= 0 else { return "--:--" }

		let totalSeconds = Int(seconds)
		let hours = totalSeconds / 3600
		let minutes = (totalSeconds % 3600) / 60
		let seconds = totalSeconds % 60

		if hours > 0 {
			return String(format: "%d:%02d:%02d", hours, minutes, seconds)
		} else {
			return String(format: "%02d:%02d", minutes, seconds)
		}
	}

	private func rateText(_ rate: Double) -> String {
		if abs(rate.rounded() - rate) < 0.001 {
			return "\(Int(rate))x"
		}
		return String(format: "%.2gx", rate)
	}
}

private struct CachedProgressBar: View {
	let currentTime: Double
	let duration: Double
	let loadedTimeRanges: [ClosedRange<Double>]
	let onSeek: (Double) -> Void
	let onSeekEnded: (Double) -> Void

	@State private var isDragging = false
	@State private var dragTime: Double = 0

	var body: some View {
		GeometryReader { geometry in
			let width = max(1, geometry.size.width)
			let height = geometry.size.height
			let effectiveTime = isDragging ? dragTime : currentTime
			let progress = normalized(effectiveTime, duration)

			ZStack(alignment: .leading) {
				Capsule()
					.fill(.white.opacity(0.22))
					.frame(height: 5)

				cacheSegments(width: width)
					.frame(height: 5)

				Capsule()
					.fill(.white)
					.frame(width: max(0, width * progress), height: 5)

				Circle()
					.fill(.white)
					.frame(width: 15, height: 15)
					.shadow(color: .black.opacity(0.35), radius: 3, y: 1)
					.offset(x: min(max(0, width * progress - 7.5), width - 15))
			}
			.frame(height: height)
			.contentShape(Rectangle())
			.gesture(
				DragGesture(minimumDistance: 0)
					.onChanged { value in
						let ratio = min(max(0, value.location.x / width), 1)
						let seconds = ratio * max(0, duration)
						isDragging = true
						dragTime = seconds
						onSeek(seconds)
					}
					.onEnded { value in
						let ratio = min(max(0, value.location.x / width), 1)
						let seconds = ratio * max(0, duration)
						isDragging = false
						dragTime = seconds
						onSeekEnded(seconds)
					}
			)
		}
	}

	@ViewBuilder
	private func cacheSegments(width: CGFloat) -> some View {
		if duration.isFinite, duration > 0, !loadedTimeRanges.isEmpty {
			ZStack(alignment: .leading) {
				ForEach(Array(loadedTimeRanges.enumerated()), id: \.offset) { _, range in
					let startRatio = min(max(range.lowerBound / duration, 0), 1)
					let endRatio = min(max(range.upperBound / duration, 0), 1)
					let start = CGFloat(startRatio) * width
					let segmentWidth = CGFloat(max(0, endRatio - startRatio)) * width

					Capsule()
						.fill(.white.opacity(0.45))
						.frame(width: max(1, segmentWidth), height: 5)
						.offset(x: min(max(0, start), width))
				}
			}
		}
	}

	private func normalized(_ current: Double, _ duration: Double) -> CGFloat {
		guard duration.isFinite, duration > 0, current.isFinite else {
			return 0
		}
		return CGFloat(min(max(current / duration, 0), 1))
	}
}
