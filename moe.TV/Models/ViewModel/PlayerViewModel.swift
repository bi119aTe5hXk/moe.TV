//
//  PlayerViewModel.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/07/04.
//

import Foundation
import AVKit
import AVFoundation

class PlayerViewModel: ObservableObject {
    @Published var avPlayer:AVPlayer?

    func loadFromUrl(url: URL) {
        avPlayer = AVPlayer(url: url)
    }
}