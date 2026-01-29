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

    func start(player: AVPlayer, ep: EpisodeDetailModel?) {
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
        if let player, let timeObserver {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        rateObserver = nil
        self.player = nil

        // Clear stale info when leaving playback.
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        #if os(macOS)
        MPNowPlayingInfoCenter.default().playbackState = .stopped
        #endif
    }

    private func installRemoteCommands(for player: AVPlayer) {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true

        commandCenter.playCommand.addTarget { [weak player] _ in
            player?.play()
            #if os(macOS)
            MPNowPlayingInfoCenter.default().playbackState = .playing
            #endif
            NowPlayingManager.shared.updatePlaybackInfo()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak player] _ in
            player?.pause()
            #if os(macOS)
            MPNowPlayingInfoCenter.default().playbackState = .paused
            #endif
            NowPlayingManager.shared.updatePlaybackInfo()
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak player] _ in
            guard let p = player else { return .commandFailed }
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
