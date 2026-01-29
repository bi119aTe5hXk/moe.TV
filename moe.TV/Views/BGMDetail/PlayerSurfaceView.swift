//
//  PlayerSurfaceView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2026/01/29.
//

import SwiftUI
import AVFoundation
import AVKit
import Combine

struct PlayerSurfaceView: View {
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

final class PlayerItemObserver: ObservableObject {
    @Published var currentStatus: AVPlayer.TimeControlStatus?
    private var cancellable: AnyCancellable?

    func observe(_ player: AVPlayer?) {
        cancellable?.cancel()
        guard let player else { currentStatus = nil; return }
        cancellable = player.publisher(for: \.timeControlStatus)
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.currentStatus = $0 }
    }

    deinit { cancellable?.cancel() }
}
