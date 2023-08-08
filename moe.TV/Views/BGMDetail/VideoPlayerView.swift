//
//  VideoPlayerView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/14.
//

import SwiftUI
import AVKit
import AVFoundation
import Combine
//TODO: PiP on tvOS & sharePlay & mediacenter
#if os(iOS) || os(tvOS)
import UIKit
struct VideoPlayerViewiOS:UIViewControllerRepresentable{
    let player: AVPlayer
//    let ep:EpisodeDetailModel?
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
        
//        controller.title = ep.name
        
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

class PlayerItemObserver {
    @Published var currentStatus: AVPlayer.TimeControlStatus?
    private var itemObservation: AnyCancellable?
    init(player: AVPlayer) {
        itemObservation = player.publisher(for: \.timeControlStatus).sink { newStatus in
            self.currentStatus = newStatus
        }
    }
}

struct VideoPlayerView: View {
    var url:URL
    var seekTime:Double
    var ep:EpisodeDetailModel?
    var isOffline:Bool
    var filename:String?
    @StateObject private var playerVM = PlayerViewModel()
    
    var body: some View {
        ZStack {
            if let avPlayer = playerVM.avPlayer {
#if os(iOS) || os(tvOS)
                let playerObserver = PlayerItemObserver(player: avPlayer)
                VideoPlayerViewiOS(player: avPlayer)
                    .onReceive(playerObserver.$currentStatus) { status in
                        switch status{
                        case nil:
                            print("nothing is here")
                        case .waitingToPlayAtSpecifiedRate:
                            print("waiting")
                        case .paused:
                            print("paused")
                            playerVM.logPlaybackPosition(player: avPlayer,
                                                         ep: ep,
                                                         isOffline: isOffline,
                                                         filename: filename)
                        case .playing:
                            print("playing")
                        case .some(_):
                            print("unknown player status")
                        }
                    }
#else
                let playerObserver = PlayerItemObserver(player: avPlayer)
                VideoPlayer(player: avPlayer)
                    .onReceive(playerObserver.$currentStatus) { status in
                        switch status{
                        case nil:
                            print("nothing is here")
                        case .waitingToPlayAtSpecifiedRate:
                            print("waiting")
                        case .paused:
                            print("paused")
                            playerVM.logPlaybackPosition(player: avPlayer,
                                                         ep: ep,
                                                         isOffline: isOffline,
                                                         filename: filename)
                        case .playing:
                            print("playing")
                        case .some(_):
                            print("unknown player status")
                        }
                    }
#endif
            }
        }.onAppear {
            playerVM.loadFromUrl(url: url)
            if let player = playerVM.avPlayer{
                
                if seekTime != 0{
                    print("seekto:\(seekTime)")
                    player.seek(to: CMTime(seconds: seekTime,
                                           preferredTimescale: Int32(NSEC_PER_SEC)),
                                toleranceBefore: CMTime.zero,
                                toleranceAfter: CMTime.zero)
                }else{
                    print("seek0")
                }
                player.play()
            }
            
        }.onDisappear{
            Task{
                if let player = playerVM.avPlayer{
                    player.pause()
                    playerVM.logPlaybackPosition(player: player,
                                                 ep: ep,
                                                 isOffline: isOffline,
                                                 filename: filename)
                }
            }
        }.edgesIgnoringSafeArea(.all)
    }
    
    
}

//struct VideoPlayerView_Previews: PreviewProvider {
//    static var previews: some View {
//        VideoPlayerView(url: URL(string: "")!, seekTime: 0, ep: EpisodeDetailModel(id: "", bangumi_id: "", bgm_eps_id: 1, name: "", thumbnail: "", status: 1, episode_no: 1, duration: "", bangumi: EPbangumiModel(id: "", bgm_id: 1, name: "", type: 1, status: 1, air_weekday: 1, eps: 1), video_files: [videoFilesListModel(id: "", status: 1, url: "", file_path: "", episode_id: "", bangumi_id: "", duration: 1)]))
//    }
//}
