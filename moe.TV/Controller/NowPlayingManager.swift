//
//  NowPlayingManager.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2026/01/29.
//
import AVFoundation
import AVKit
import MediaPlayer
import SwiftUI

// MARK: - System Now Playing (macOS Control Center / menu bar)
final class NowPlayingManager {
    static let shared = NowPlayingManager()
    private init() {}

    private weak var player: AVPlayer?
    private var timeObserver: Any?
    private var rateObserver: NSKeyValueObservation?

    // Remote command target tokens (avoid stacking handlers across videos)
    private var playTarget: Any?
    private var pauseTarget: Any?
    private var toggleTarget: Any?
    
    private var skipForwardTarget: Any?
    private var skipBackwardTarget: Any?

    func start(player: AVPlayer, ep: EpisodeDetailModel?) {
        // If the same player is started again (common with SwiftUI re-render / Catalyst),
        // do NOT call stop() because stop() pauses playback and removes command targets.
        if let current = self.player, current === player {
            updateMetadata(ep: ep)
            updatePlaybackInfo()
            return
        }

        stop()
        self.player = player

        // 1) Publish static metadata first (title/artist/etc.)
        updateMetadata(ep: ep)

        // 2) Become eligible for system transport controls by registering at least one remote command.
        installRemoteCommands(for: player)

        // 3) Keep playback info (elapsed/rate/state) reasonably up to date.
        observePlayback(for: player)

        // 4) On macOS you must set playbackState when playback starts/stops.
        #if os(macOS)
        MPNowPlayingInfoCenter.default().playbackState = player.rate > 0 ? .playing : .paused
        #endif
    }

    func updateMetadata(ep: EpisodeDetailModel?) {
        guard let player = player else { return }

        let item = player.currentItem
        let durationSeconds = item.map { CMTimeGetSeconds($0.duration) }

        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        nowPlayingInfo[MPMediaItemPropertyTitle] = ep?.name ?? ""
        nowPlayingInfo[MPMediaItemPropertyArtist] = ep?.name_cn ?? ""

        if let d = durationSeconds, d.isFinite, d > 0 {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = d
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func stop() {
        // Stop old playback to avoid lingering audio when remote commands fire.
        player?.pause()

        if let player, let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        rateObserver = nil

        // Remove remote command handlers so we don't stack multiple targets.
        removeRemoteCommandTargets()

        self.player = nil

        // Clear stale info when leaving playback.
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        #if os(macOS)
        MPNowPlayingInfoCenter.default().playbackState = .stopped
        #endif
    }

    private func removeRemoteCommandTargets() {
        let commandCenter = MPRemoteCommandCenter.shared()

        if let playTarget { commandCenter.playCommand.removeTarget(playTarget) }
        if let pauseTarget { commandCenter.pauseCommand.removeTarget(pauseTarget) }
        if let toggleTarget { commandCenter.togglePlayPauseCommand.removeTarget(toggleTarget) }
        if let skipForwardTarget { commandCenter.skipForwardCommand.removeTarget(skipForwardTarget) }
        if let skipBackwardTarget { commandCenter.skipBackwardCommand.removeTarget(skipBackwardTarget) }
        
        skipForwardTarget = nil
        skipBackwardTarget = nil

        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        playTarget = nil
        pauseTarget = nil
        toggleTarget = nil

        // Optional: disable when not playing.
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.togglePlayPauseCommand.isEnabled = false
    }

    private func installRemoteCommands(for player: AVPlayer) {
        // Ensure we don't accumulate multiple handlers when starting multiple times.
        removeRemoteCommandTargets()

        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [10]
        commandCenter.skipBackwardCommand.preferredIntervals = [10]

        playTarget = commandCenter.playCommand.addTarget { [weak self] _ in
            self?.player?.play()
            #if os(macOS)
            MPNowPlayingInfoCenter.default().playbackState = .playing
            #endif
            NowPlayingManager.shared.updatePlaybackInfo()
            return .success
        }

        pauseTarget = commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.player?.pause()
            #if os(macOS)
            MPNowPlayingInfoCenter.default().playbackState = .paused
            #endif
            NowPlayingManager.shared.updatePlaybackInfo()
            return .success
        }

        toggleTarget = commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let p = self?.player else { return .commandFailed }
            if p.rate == 0 {
                p.play()
                #if os(macOS)
                MPNowPlayingInfoCenter.default().playbackState = .playing
                #endif
            } else {
                p.pause()
                #if os(macOS)
                MPNowPlayingInfoCenter.default().playbackState = .paused
                #endif
            }
            NowPlayingManager.shared.updatePlaybackInfo()
            return .success
        }
        skipForwardTarget = commandCenter.skipForwardCommand.addTarget { [weak self] event in
            guard let self,
                  let e = event as? MPSkipIntervalCommandEvent,
                  let player = self.player
            else { return .commandFailed }

            let wasPlaying = player.rate > 0
            self.seek(player: player, by: e.interval, keepPlaying: wasPlaying)
            return .success
        }

        skipBackwardTarget = commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            guard let self,
                  let e = event as? MPSkipIntervalCommandEvent,
                  let player = self.player
            else { return .commandFailed }

            let wasPlaying = player.rate > 0
            self.seek(player: player, by: -e.interval, keepPlaying: wasPlaying)
            return .success
        }
    }
    private func seek(player: AVPlayer, by delta: Double, keepPlaying: Bool) {
        let current = player.currentTime().seconds
        let target = current + delta

        let duration = player.currentItem?.duration.seconds
        let clamped: Double
        if let d = duration, d.isFinite, d > 0 {
            clamped = min(max(0, target), d)
        } else {
            clamped = max(0, target)
        }

        let time = CMTime(seconds: clamped, preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
            if keepPlaying { player.play() }
            self.updatePlaybackInfo()
        }
    }

    private func observePlayback(for player: AVPlayer) {
        // Update elapsed time occasionally so the system can infer progress.
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 2, preferredTimescale: 1), queue: .main) { _ in
            NowPlayingManager.shared.updatePlaybackInfo()
        }

        // Update when playback rate changes (play/pause, buffering transitions).
        rateObserver = player.observe(\.rate, options: [.initial, .new]) { _, _ in
            NowPlayingManager.shared.updatePlaybackInfo()
            #if os(macOS)
            let isPlaying = (NowPlayingManager.shared.player?.rate ?? 0) > 0
            MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
            #endif
        }
    }

    private func updatePlaybackInfo() {
        guard let player else { return }
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
