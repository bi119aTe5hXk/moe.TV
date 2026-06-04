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

enum PlayerSurfaceMode {
	case system
	case custom
}
struct PlayerSurfaceView: View {
	let player: AVPlayer
	let ep: EpisodeDetailModel?
	let playerVM: PlayerViewController
	@ObservedObject var observer: PlayerItemObserver
	let onStatus: (AVPlayer.TimeControlStatus?) -> Void
	var mode: PlayerSurfaceMode = .custom

	var body: some View {
		Group {
			switch mode {
			case .system:
				SystemPlayerSurfaceView(
					player: player,
					ep: ep,
					playerVM: playerVM,
					observer: observer,
					onStatus: onStatus
				)

			case .custom:
				CustomPlayerSurfaceView(
					player: player,
					ep: ep,
					playerVM: playerVM,
					observer: observer,
					onStatus: onStatus
				)
			}
		}
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
