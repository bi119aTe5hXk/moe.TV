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
//TODO: PiP on tvOS
#if os(iOS) || os(tvOS)
struct VideoPlayerViewiOS:UIViewControllerRepresentable{
    let player: AVPlayer
    let ep:EpisodeDetailModel
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playback)
                try audioSession.setActive(true, options: [])
            } catch {
                print("Setting category to AVAudioSessionCategoryPlayback failed.")
            }
        
//        var playerLayer = AVPlayerLayer(player: player)
//        var pipController: AVPictureInPictureController?
//        playerLayer.videoGravity = .resizeAspect
//        layer.addSublayer(playerLayer)
//        playerLayer.frame = self.bounds
        
        controller.player = player
        controller.modalPresentationStyle = .automatic
        controller.showsPlaybackControls = true
        controller.allowsPictureInPicturePlayback = true
        
        controller.title = ep.name
        
        if AVPictureInPictureController.isPictureInPictureSupported() {
//            pipController = AVPictureInPictureController(playerLayer: playerLayer)!
            print("canpip")
            
        }else{
            print("nopip")
        }
        
        
        return controller
    }
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        
    }
}
#endif
//TODO: PiP macOS support
//#if os(macOS)
//struct VideoPlayerViewMacOS:NSViewControllerRepresentable{
//    typealias NSViewControllerType = NSViewController
//    let player: AVPlayer
//    func makeNSViewController(context: Context) -> NSViewController {
//
//        return nil
//    }
//
//    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
//
//    }
//}
//#endif

struct VideoPlayerView: View {
    var url:URL
    var seekTime:Double
    var ep:EpisodeDetailModel
    
    @StateObject private var playerViewModel = PlayerViewModel()
    
    var body: some View {
        ZStack {
            if let avPlayer = playerViewModel.avPlayer {
#if os(iOS) || os(tvOS)
                VideoPlayerViewiOS(player: avPlayer,ep: ep)
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
                    player.pause()
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
//            updateBGMEPwatched(epID: ep.bgm_eps_id) { result, data in
//                print(data)
//            }
            updateBGMSBEPwatched(subject_id: ep.bangumi.bgm_id,
                                 episode_id: ep.bgm_eps_id) { result, data in
                print(data)
            }
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
        VideoPlayerView(url: URL(string: "")!, seekTime: 0, ep: EpisodeDetailModel(id: "", bangumi_id: "", bgm_eps_id: 1, name: "", thumbnail: "", status: 1, episode_no: 1, duration: "", bangumi: EPbangumiModel(id: "", bgm_id: 1, name: "", type: 1, status: 1, air_weekday: 1, eps: 1), video_files: [videoFilesListModel(id: "", status: 1, url: "", file_path: "", episode_id: "", bangumi_id: "", duration: 1)]))
    }
}
