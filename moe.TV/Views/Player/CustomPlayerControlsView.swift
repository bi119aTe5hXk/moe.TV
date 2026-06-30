//
//  CustomPlayerControlsView.swift
//  moe.TV
//
//  First-pass custom playback controls with cached-range visualization.
//

import AVFoundation
import SwiftUI
#if os(iOS)
import GameController
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct CustomPlayerControlsView: View {
	@ObservedObject var playerVM: PlayerViewController
	var isPictureInPictureSupported = false
	var isPictureInPictureActive = false
	var onPictureInPictureToggle: (() -> Void)?
	var onFullScreenToggle: (() -> Void)?
	var title: String?
	var subtitle: String?
	var onClose: (() -> Void)?

	@State private var isControlsVisible = true
	@State private var scrubTime: Double = 0
	@State private var isScrubbing = false
	@State private var hideControlsTask: Task<Void, Never>?
	@State private var isVolumeHUDVisible = false
	@State private var hideVolumeHUDTask: Task<Void, Never>?
	@State private var actionHUD: PlayerActionHUD?
	@State private var hideActionHUDTask: Task<Void, Never>?

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
					.background(Color.black.opacity(0.24))
					.transition(.opacity)
				}

#if !os(tvOS)
			if isVolumeHUDVisible {
				volumeHUD
					.transition(.opacity.combined(with: .scale(scale: 0.96)))
			}

			if let actionHUD {
				actionHUDView(actionHUD)
					.transition(.opacity.combined(with: .scale(scale: 0.96)))
			}
#endif
		}
		.overlay(keyboardInput)
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
			hideVolumeHUDTask?.cancel()
			hideActionHUDTask?.cancel()
		}
	}

	private var topBar: some View {
		HStack(spacing: 12) {
			if let onClose {
				Button(action: {
					onClose()
				}) {
					Image(systemName: "xmark.circle.fill")
						.font(.system(size: 30, weight: .semibold))
						.foregroundColor(.white)
						.shadow(radius: 4)
						.frame(width: 54, height: 54)
						.background(.black.opacity(0.34), in: Circle())
				}
				.buttonStyle(.plain)
				.accessibilityLabel("Close")
			}

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
		.padding(.horizontal, 28)
		.padding(.top, 22)
	}

#if !os(tvOS)
	private func volumeIndicator(sliderWidth: CGFloat = 92, showsPercent: Bool = true) -> some View {
		HStack(spacing: 8) {
			Image(systemName: volumeSystemImage)
				.font(.system(size: 15, weight: .medium))
				.frame(width: 18)

			Slider(
				value: Binding(
					get: { clampedVolume },
					set: { value in
						hideControlsTask?.cancel()
						playerVM.setVolume(value)
					}
				),
				in: 0...1,
				onEditingChanged: { isEditing in
					if isEditing {
						hideControlsTask?.cancel()
					} else {
						showControlsTemporarily()
					}
				}
			)
			.tint(.white)
			.frame(width: sliderWidth)

			if showsPercent {
				Text(volumePercentText)
					.font(.system(.caption, design: .rounded).weight(.semibold))
					.monospacedDigit()
					.frame(minWidth: 38, alignment: .trailing)
			}
		}
		.padding(.horizontal, 12)
		.frame(height: 32)
		.background(.white.opacity(0.16), in: Capsule())
		.accessibilityLabel("Volume \(volumePercentText)")
	}

	private var volumeHUD: some View {
		VStack(spacing: 10) {
			Image(systemName: volumeSystemImage)
				.font(.system(size: 30, weight: .semibold))

			Text(volumePercentText)
				.font(.system(.title3, design: .rounded).weight(.semibold))
				.monospacedDigit()

			GeometryReader { geometry in
				ZStack(alignment: .leading) {
					Capsule()
						.fill(.white.opacity(0.22))

					Capsule()
						.fill(.white)
						.frame(width: geometry.size.width * CGFloat(clampedVolume))
				}
			}
			.frame(width: 132, height: 5)
		}
		.padding(.horizontal, 22)
		.padding(.vertical, 18)
		.background(.black.opacity(0.68), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
		.shadow(color: .black.opacity(0.35), radius: 12, y: 4)
	}

	private func actionHUDView(_ hud: PlayerActionHUD) -> some View {
		HStack(spacing: 10) {
			Image(systemName: hud.systemImage)
				.font(.system(size: 21, weight: .semibold))

			Text(hud.message)
				.font(.system(.subheadline, design: .rounded).weight(.semibold))
				.lineLimit(1)
		}
		.padding(.horizontal, 18)
		.padding(.vertical, 14)
		.background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
		.shadow(color: .black.opacity(0.35), radius: 12, y: 4)
	}
#endif

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
			if hasTitleText {
				titleBlock
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding(.bottom, 2)
			}

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

			controlRows
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

	private var controlRows: some View {
		ViewThatFits(in: .horizontal) {
			regularControlRow
			compactControlRows
		}
	}

	private var regularControlRow: some View {
		HStack(spacing: 12) {
			transportControls
			timeLabel
			Spacer(minLength: 8)
			secondaryControls(isCompact: false)
		}
	}

	private var compactControlRows: some View {
		VStack(spacing: 8) {
			HStack(spacing: 10) {
				transportControls
				timeLabel
				Spacer(minLength: 6)
				fullScreenButton
			}

			HStack(spacing: 8) {
				#if !os(tvOS)
				GeometryReader { geometry in
					volumeIndicator(sliderWidth: compactVolumeSliderWidth(for: geometry.size.width), showsPercent: true)
				}
				.frame(height: 32)
				#endif
				secondaryControls(isCompact: true)
			}
		}
	}

	#if !os(tvOS)
	private func compactVolumeSliderWidth(for availableWidth: CGFloat) -> CGFloat {
		let hasPictureInPicture = isPictureInPictureSupported && onPictureInPictureToggle != nil
		let secondaryControlsWidth: CGFloat = hasPictureInPicture ? 142 : 96
		let volumeChromeWidth: CGFloat = 96
		let usableWidth = availableWidth - secondaryControlsWidth - volumeChromeWidth
		return max(82, min(160, usableWidth))
	}
	#endif

	private var transportControls: some View {
		HStack(spacing: 8) {
			backwardButton
			playPauseButton
			forwardButton
		}
	}

	private var backwardButton: some View {
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
	}

	private var playPauseButton: some View {
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
	}

	private var forwardButton: some View {
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
	}

	private var timeLabel: some View {
		Text(timeText)
			.font(.system(.caption, design: .monospaced))
			.lineLimit(1)
			.minimumScaleFactor(0.7)
			.frame(minWidth: 78, alignment: .leading)
	}

	@ViewBuilder
	private func secondaryControls(isCompact: Bool) -> some View {
		HStack(spacing: isCompact ? 6 : 12) {
			#if !os(tvOS)
			if !isCompact {
				volumeIndicator()
			}
			screenshotButton
			#endif
			playbackRateMenu
			pictureInPictureButton
			if !isCompact {
				fullScreenButton
			}
		}
	}

	#if !os(tvOS)
	private var screenshotButton: some View {
		Button {
			playerVM.copyCurrentFrameToPasteboard { success in
				showActionHUD(
					success
						? PlayerActionHUD(systemImage: "checkmark.circle.fill", message: "Copied to Clipboard")
						: PlayerActionHUD(systemImage: "exclamationmark.triangle.fill", message: "Screenshot Failed")
				)
			}
			showControlsTemporarily()
		} label: {
			Image(systemName: "camera")
				.font(.system(size: 19, weight: .medium))
				.frame(width: 40, height: 36)
		}
		.buttonStyle(.plain)
		.accessibilityLabel("Copy current frame")
	}
	#endif

	private var playbackRateMenu: some View {
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
				.frame(minWidth: 44, minHeight: 32)
				.padding(.horizontal, 6)
				.background(.white.opacity(0.16), in: Capsule())
		}
		.buttonStyle(.plain)
		.accessibilityLabel("Playback speed")
	}

	@ViewBuilder
	private var pictureInPictureButton: some View {
		if isPictureInPictureSupported, let onPictureInPictureToggle {
			Button {
				onPictureInPictureToggle()
				showControlsTemporarily()
			} label: {
				Image(systemName: isPictureInPictureActive ? "pip.exit" : "pip.enter")
					.font(.system(size: 19, weight: .medium))
					.frame(width: 40, height: 36)
			}
			.buttonStyle(.plain)
			.accessibilityLabel("Picture in Picture")
		}
	}

	@ViewBuilder
	private var fullScreenButton: some View {
		if let onFullScreenToggle {
			Button {
				onFullScreenToggle()
				showControlsTemporarily()
			} label: {
				Image(systemName: "arrow.up.left.and.arrow.down.right")
					.font(.system(size: 19, weight: .medium))
					.frame(width: 40, height: 36)
			}
			.buttonStyle(.plain)
			.accessibilityLabel("Full Screen")
		}
	}

	private var titleBlock: some View {
		VStack(alignment: .leading, spacing: 4) {
			if let title, !title.isEmpty {
				Text(title)
					.font(.title3.weight(.semibold))
					.lineLimit(1)
					.minimumScaleFactor(0.75)
					.shadow(radius: 4)
			}

			if let subtitle, !subtitle.isEmpty {
				Text(subtitle)
					.font(.subheadline)
					.foregroundStyle(.white.opacity(0.82))
					.lineLimit(1)
					.minimumScaleFactor(0.75)
					.shadow(radius: 4)
			}
		}
	}

	private var hasTitleText: Bool {
		(title?.isEmpty == false) || (subtitle?.isEmpty == false)
	}

	private var timeText: String {
		"\(formatTime(isScrubbing ? scrubTime : playerVM.currentTime)) / \(formatTime(playerVM.duration))"
	}

#if !os(tvOS)
	private var clampedVolume: Float {
		min(1, max(0, playerVM.volume))
	}

	private var volumePercentText: String {
		"\(Int((clampedVolume * 100).rounded()))%"
	}

	private var volumeSystemImage: String {
		if clampedVolume <= 0 {
			return "speaker.slash.fill"
		} else if clampedVolume < 0.35 {
			return "speaker.wave.1.fill"
		} else if clampedVolume < 0.75 {
			return "speaker.wave.2.fill"
		} else {
			return "speaker.wave.3.fill"
		}
	}
#endif

	@ViewBuilder
	private var keyboardInput: some View {
#if os(tvOS) || os(visionOS)
		EmptyView()
#else
		PlayerKeyboardInputView { action in
			handleKeyboardAction(action)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.accessibilityHidden(true)
#endif
	}

#if !os(tvOS)
	private func handleKeyboardAction(_ action: PlayerKeyboardAction) {
		switch action {
		case .playPause:
			playerVM.togglePlayPause()
		case .backward:
			playerVM.seek(by: -15, autoPlay: playerVM.isPlaying)
		case .forward:
			playerVM.seek(by: 15, autoPlay: playerVM.isPlaying)
		case .volumeUp:
			playerVM.adjustVolume(by: 0.05)
			showVolumeHUD()
		case .volumeDown:
			playerVM.adjustVolume(by: -0.05)
			showVolumeHUD()
		}

		showControlsTemporarily()
	}
#endif

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

#if !os(tvOS)
	private func showVolumeHUD() {
		hideVolumeHUDTask?.cancel()

		withAnimation(.easeInOut(duration: 0.12)) {
			isVolumeHUDVisible = true
		}

		hideVolumeHUDTask = Task { @MainActor in
			try? await Task.sleep(nanoseconds: 900_000_000)
			if !Task.isCancelled {
				withAnimation(.easeInOut(duration: 0.18)) {
					isVolumeHUDVisible = false
				}
			}
		}
	}

	private func showActionHUD(_ hud: PlayerActionHUD) {
		hideActionHUDTask?.cancel()

		withAnimation(.easeInOut(duration: 0.12)) {
			actionHUD = hud
		}

		hideActionHUDTask = Task { @MainActor in
			try? await Task.sleep(nanoseconds: 1_300_000_000)
			if !Task.isCancelled {
				withAnimation(.easeInOut(duration: 0.18)) {
					actionHUD = nil
				}
			}
		}
	}
#endif

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
#if !os(tvOS)
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
#endif
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

#if !os(tvOS)
private enum PlayerKeyboardAction {
	case playPause
	case backward
	case forward
	case volumeUp
	case volumeDown
}
#endif

private struct PlayerActionHUD {
	let systemImage: String
	let message: String
}

#if os(iOS)
private struct PlayerKeyboardInputView: UIViewRepresentable {
	let onAction: (PlayerKeyboardAction) -> Void

	func makeUIView(context: Context) -> KeyboardInputUIView {
		let view = KeyboardInputUIView()
		view.onAction = onAction
		DispatchQueue.main.async {
			view.becomeFirstResponder()
		}
		return view
	}

	func updateUIView(_ uiView: KeyboardInputUIView, context: Context) {
		uiView.onAction = onAction
		DispatchQueue.main.async {
			uiView.becomeFirstResponder()
		}
	}
}

private final class KeyboardInputUIView: UIView {
	var onAction: ((PlayerKeyboardAction) -> Void)?
	private weak var capturedKeyboardInput: GCKeyboardInput?
	private var keyboardConnectObserver: NSObjectProtocol?
	private var keyboardDisconnectObserver: NSObjectProtocol?

	override func didMoveToWindow() {
		super.didMoveToWindow()
		if window == nil {
			stopKeyboardCapture()
		} else {
			startKeyboardCapture()
		}
	}

	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		false
	}

	deinit {
		stopKeyboardCapture()
	}

	private func startKeyboardCapture() {
		installKeyboardObserversIfNeeded()
		captureCurrentKeyboard()
	}

	private func stopKeyboardCapture() {
		capturedKeyboardInput?.keyChangedHandler = nil
		capturedKeyboardInput = nil

		if let keyboardConnectObserver {
			NotificationCenter.default.removeObserver(keyboardConnectObserver)
			self.keyboardConnectObserver = nil
		}

		if let keyboardDisconnectObserver {
			NotificationCenter.default.removeObserver(keyboardDisconnectObserver)
			self.keyboardDisconnectObserver = nil
		}
	}

	private func installKeyboardObserversIfNeeded() {
		guard keyboardConnectObserver == nil else { return }

		keyboardConnectObserver = NotificationCenter.default.addObserver(
			forName: .GCKeyboardDidConnect,
			object: nil,
			queue: .main
		) { [weak self] _ in
			self?.captureCurrentKeyboard()
		}

		keyboardDisconnectObserver = NotificationCenter.default.addObserver(
			forName: .GCKeyboardDidDisconnect,
			object: nil,
			queue: .main
		) { [weak self] _ in
			self?.captureCurrentKeyboard()
		}
	}

	private func captureCurrentKeyboard() {
		guard window != nil else { return }

		let keyboardInput = GCKeyboard.coalesced?.keyboardInput
		guard keyboardInput !== capturedKeyboardInput else { return }

		capturedKeyboardInput?.keyChangedHandler = nil
		capturedKeyboardInput = keyboardInput

		keyboardInput?.keyChangedHandler = { [weak self] _, _, keyCode, pressed in
			guard pressed, let action = Self.action(for: keyCode) else { return }
			DispatchQueue.main.async {
				self?.onAction?(action)
			}
		}
	}

	private static func action(for keyCode: GCKeyCode) -> PlayerKeyboardAction? {
		switch keyCode {
		case .spacebar:
			return .playPause
		case .leftArrow:
			return .backward
		case .rightArrow:
			return .forward
		case .upArrow:
			return .volumeUp
		case .downArrow:
			return .volumeDown
		default:
			return nil
		}
	}
}
#elseif os(macOS)
private struct PlayerKeyboardInputView: NSViewRepresentable {
	let onAction: (PlayerKeyboardAction) -> Void

	func makeNSView(context: Context) -> KeyboardInputNSView {
		let view = KeyboardInputNSView()
		view.onAction = onAction
		DispatchQueue.main.async {
			view.window?.makeFirstResponder(view)
		}
		return view
	}

	func updateNSView(_ nsView: KeyboardInputNSView, context: Context) {
		nsView.onAction = onAction
		DispatchQueue.main.async {
			nsView.window?.makeFirstResponder(nsView)
		}
	}
}

private final class KeyboardInputNSView: NSView {
	var onAction: ((PlayerKeyboardAction) -> Void)?
	private var localKeyMonitor: Any?

	override var acceptsFirstResponder: Bool {
		true
	}

	override func viewDidMoveToWindow() {
		super.viewDidMoveToWindow()
		if window == nil {
			stopMonitoring()
		} else {
			startMonitoring()
		}
	}

	deinit {
		stopMonitoring()
	}

	override func keyDown(with event: NSEvent) {
		if !handle(event) {
			super.keyDown(with: event)
		}
	}

	private func startMonitoring() {
		window?.makeFirstResponder(self)
		guard localKeyMonitor == nil else { return }
		localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
			guard let self else { return event }
			return self.handle(event) ? nil : event
		}
	}

	private func stopMonitoring() {
		if let localKeyMonitor {
			NSEvent.removeMonitor(localKeyMonitor)
			self.localKeyMonitor = nil
		}
	}

	private func handle(_ event: NSEvent) -> Bool {
		guard event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty else {
			return false
		}

		switch event.keyCode {
		case 49:
			onAction?(.playPause)
		case 123:
			onAction?(.backward)
		case 124:
			onAction?(.forward)
		case 126:
			onAction?(.volumeUp)
		case 125:
			onAction?(.volumeDown)
		default:
			return false
		}

		return true
	}
}
#endif
