//
//  VideoPlayerView.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/14.
//

import SwiftUI
import AVKit
import AVFoundation


class PlayerViewModel: ObservableObject {

    @Published var avPlayer:AVPlayer?

    func loadFromUrl(url: URL) {
        avPlayer = AVPlayer(url: url)
    }
}
#if os(iOS)
struct VideoPlayerViewiOS:UIViewControllerRepresentable{
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.modalPresentationStyle = .fullScreen
        controller.showsPlaybackControls = true
        return controller
    }
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        
    }
}
#endif

struct VideoPlayerView: View {
    var url:URL
    var seekTime:Double
    var ep:BGMEpisode
    
    @StateObject private var playerViewModel = PlayerViewModel()
    
    var body: some View {
        ZStack {
            if let avPlayer = playerViewModel.avPlayer {
#if os(iOS)
                VideoPlayerViewiOS(player: avPlayer)
#else
                VideoPlayer(player: avPlayer)
#endif
            }
        }.onAppear {
            playerViewModel.loadFromUrl(url: url)
            if let player = playerViewModel.avPlayer{
                if seekTime != 0{
                    print("seekto:\(seekTime)")
                    player.seek(to: CMTime(seconds: seekTime,
                                           preferredTimescale: Int32(NSEC_PER_SEC)),
                                toleranceBefore: CMTime.zero,
                                toleranceAfter: CMTime.zero)
                }
                player.play()
            }
            
        }.onDisappear{
            Task{
                if let player = playerViewModel.avPlayer{
                    logPlaybackPosition(player: player)
                }
            }
        }.edgesIgnoringSafeArea(.all)
        
    }
    
    func logPlaybackPosition(player:AVPlayer) {
        let currentItem = player.currentItem;
        let currentTime = CMTimeGetSeconds(currentItem!.currentTime())
        let percent = CMTimeGetSeconds(currentItem!.currentTime()) / CMTimeGetSeconds(currentItem!.duration)
        
        var isFinished = false
        if percent > 0.95{
            isFinished = true
        }
        print("logprogress:\(currentTime),\(percent)")
        
        sentEPWatchProgress(ep_id: ep.id,
                            bangumi_id: ep.bangumi_id,
                            last_watch_position: currentTime,
                            percentage: percent,
                            is_finished: isFinished
        ) { result, data in
            print(data)
        }
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView(url: URL(string: "")!, seekTime: 0, ep: BGMEpisode(id: "", bangumi_id: "", bgm_eps_id: 0, name: "", thumbnail: "", status: 0, episode_no: 0, duration: ""))
    }
}