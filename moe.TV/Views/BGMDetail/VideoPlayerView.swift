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
	let playerVM:PlayerViewModel
    let ep:EpisodeDetailModel?

	private let settingsHandler = SettingsHandler()

	func makeUIViewController(context: UIViewControllerRepresentableContext<VideoPlayerViewiOS>) -> AVPlayerViewController {
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


		//TODO: fix playback rate not display correctly
		//set playback rate
		let rate = Float(settingsHandler.getPlaybackRate())
		print("rate: \(rate)")
		controller.player?.rate = rate
		let avRate = AVPlaybackSpeed(rate: rate, localizedName: "\(Float(settingsHandler.getPlaybackRate()))x")
		controller.selectSpeed(avRate)

		setPlayerRate(player: controller.player!, rate: rate)

		print(
			"selectedrate: \(String(describing: controller.selectedSpeed?.rate))"
		)

		let metadata = playerVM.setMatadata(ep: ep)
		controller.player?.currentItem?.externalMetadata = metadata
        
        if AVPictureInPictureController.isPictureInPictureSupported() {
//            pipController = AVPictureInPictureController(playerLayer: playerLayer)!
            print("canpip")
            
        }else{
            print("nopip")
        }

//		if UIDevice.current.userInterfaceIdiom == .phone{
//			print("try set landscape")
//			let value = UIInterfaceOrientation.landscapeLeft.rawValue
//			UIDevice.current.setValue(value, forKey: "orientation")
//		}
		controller.player?.play()


        return controller
    }
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<VideoPlayerViewiOS>) {
		uiViewController.player = player
    }

	func setPlayerRate(player: AVPlayer, rate: Float) {
			// AVFoundation wants us to do most things on the main queue.
		DispatchQueue.main.async {
			if (rate == player.rate) {
				return
			}
			if (rate > 2.0 || rate < -2.0) {
				let playerItem = player.currentItem
				player.replaceCurrentItem(with: nil)
				player.replaceCurrentItem(with: playerItem)
				player.rate = rate
			} else {
					// No problems "out of the box" with rates in the range [-2.0,2.0].
				player.rate = rate
			}
		}
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
	var bgmItem:BangumiItemModel?
    var ep:EpisodeDetailModel?
    var isOffline:Bool
    var filename:String?
    @StateObject private var playerVM = PlayerViewModel()

	private let settingsHandler = SettingsHandler()

    var body: some View {
        ZStack {
            if let avPlayer = playerVM.avPlayer {

#if os(iOS) || os(tvOS)
                let playerObserver = PlayerItemObserver(player: avPlayer)
				VideoPlayerViewiOS(player: avPlayer, playerVM: playerVM, ep: ep)
                    .onReceive(playerObserver.$currentStatus) { status in
                        switch status{
                        case nil:
                            print("nothing is here")
                        case .waitingToPlayAtSpecifiedRate:
                            print("waiting")
                        case .paused:
                            print("paused")
                            playerVM.logPlaybackPosition(player: avPlayer,
														 bgmItem: bgmItem,
                                                         ep: ep,
                                                         isOffline: isOffline,
                                                         filename: filename)
                        case .playing:
                            print("playing")
                        case .some(_):
                            print("unknown player status")
                        }

                    }
					.persistentSystemOverlays(.hidden)

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
														 bgmItem: bgmItem,
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
        }

		.edgesIgnoringSafeArea(.all)
		.onAppear {
#if os(iOS)
			if UIDevice.current.userInterfaceIdiom == .phone && settingsHandler.getLandscapePlayback(){
				OrientationController.shared.unlockOrientation()
				OrientationController.shared.currentOrientation = .landscapeRight
			}
#endif
            playerVM.loadFromUrl(url: url)
            if let player = playerVM.avPlayer{
				player.currentItem?.preferredForwardBufferDuration = TimeInterval(60)
				player.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true

                if seekTime != 0{
                    print("seekto:\(seekTime)")
                    player.seek(to: CMTime(seconds: seekTime,
                                           preferredTimescale: Int32(NSEC_PER_SEC)),
                                toleranceBefore: CMTime.zero,
                                toleranceAfter: CMTime.zero)
                }else{
                    print("seek0")
                }

//				print("playbackrate:\(Float(settingsHandler.getPlaybackRate()))")
//				player.rate = Float(settingsHandler.getPlaybackRate())
//				player.playImmediately(atRate: Float(settingsHandler.getPlaybackRate()))
//				player.play()
            }
            
        }
		.onDisappear{
            Task{
                if let player = playerVM.avPlayer{
                    player.pause()
                    playerVM.logPlaybackPosition(player: player,
												 bgmItem: bgmItem,
                                                 ep: ep,
                                                 isOffline: isOffline,
                                                 filename: filename)
                }
#if os(iOS)
				if UIDevice.current.userInterfaceIdiom == .phone && settingsHandler.getLandscapePlayback(){
//					OrientationController.shared.unlockOrientation()
//					OrientationController.shared.currentOrientation = .portrait
					if let w = SceneDelegate().window {
						OrientationController.shared.lockOrientation(to: .portrait,
																	 onWindow: w)

					}
				}
#endif
            }

        }


    }
}



//struct VideoPlayerView_Previews: PreviewProvider {
//    static var previews: some View {
//        VideoPlayerView(url: URL(string: "")!, seekTime: 0, ep: EpisodeDetailModel(id: "", bangumi_id: "", bgm_eps_id: 1, name: "", thumbnail: "", status: 1, episode_no: 1, duration: "", bangumi: EPbangumiModel(id: "", bgm_id: 1, name: "", type: 1, status: 1, air_weekday: 1, eps: 1), video_files: [videoFilesListModel(id: "", status: 1, url: "", file_path: "", episode_id: "", bangumi_id: "", duration: 1)]))
//    }
//}
