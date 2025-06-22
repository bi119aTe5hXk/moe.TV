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
	let playerVM:PlayerViewController
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


		let metadata = playerVM.setMatadata(ep: ep)
		controller.player?.currentItem?.externalMetadata = metadata
		controller.player?.currentItem?.preferredForwardBufferDuration = TimeInterval(60.0)

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

		let rate = Float(settingsHandler.getPlaybackRate())
//		print("rate: \(rate)")
		if let thePlayer = controller.player {
			thePlayer.playImmediately(atRate: rate )
			thePlayer.defaultRate = rate
			thePlayer.currentItem?.preferredForwardBufferDuration = TimeInterval(60.0)
		}



        return controller
    }
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<VideoPlayerViewiOS>) {
		uiViewController.player = player
    }


}
#endif
//TODO: PiP macOS support
//#if os(macOS)
//struct VideoPlayerViewMacOS:NSViewControllerRepresentable{
//    typealias NSViewControllerType = NSViewController
//    let player: AVPlayer
//    func makeNSViewController(context: Context) -> NSViewController {
//		let controller = AVPlayerViewController()
//        return controller
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
	@Binding var bgmItem:BangumiItemModel?
    var ep:EpisodeDetailModel?
    var isOffline:Bool
    var filename:String?
	@StateObject private var playerVM = PlayerViewController()
	var detailVC:BangumiDetailViewController?

	var isBGMTVWatched:Bool

	private let settingsHandler = SettingsHandler()

    var body: some View {
		ZStack{
			if let avPlayer = playerVM.avPlayer {
#if os(iOS)
				if settingsHandler
					.getShowBgmtvWebWhilePlaying() &&
					(detailVC != nil) &&
					UIDevice.current.userInterfaceIdiom != .phone
				{
						//player with navbar & webview
					GeometryReader { geometry in
						NavigationView{
							HStack{
								ZStack {
									let playerObserver = PlayerItemObserver(player: avPlayer)
									VideoPlayerViewiOS(player: avPlayer, playerVM: playerVM, ep: ep)
										.onReceive(playerObserver.$currentStatus) { status in
											playerVM
												.playerObserverHandler(
													status: status,
													bgmItem: bgmItem,
													filename: filename,
													ep: ep,
													isOffline: isOffline,
													isBGMTVWatched: isBGMTVWatched
												)
										}
										.persistentSystemOverlays(.hidden)
								}.frame(maxWidth: .infinity)
								if let theEP = ep{
									if UIDevice.current.userInterfaceIdiom == .pad {

										if let bgm_eps_id = theEP.bgm_eps_id{
											let urlString = "https://bgm.tv/ep/\(String(bgm_eps_id))"

											WebView(url: URL(string: urlString)!)
												.ignoresSafeArea()
												.navigationBarTitleDisplayMode(.inline)
												.frame(width: geometry.size.width*0.2)
												.navigationTitle(theEP.name ?? "")
												//										.navigationSubtitle(theEP.name_cn ?? "")
												.navigationBarItems(leading:
																		Button(action: {
													detailVC?.presentVideoView = false
												}) {
													Text("Close")
												}
												)
										}
									}
								}
							}
						}
					}
				}else{
						//full screen player
					ZStack {
						let playerObserver = PlayerItemObserver(player: avPlayer)
						VideoPlayerViewiOS(player: avPlayer, playerVM: playerVM, ep: ep)
							.onReceive(playerObserver.$currentStatus) { status in
								playerVM
									.playerObserverHandler(
										status: status,
										bgmItem: bgmItem,
										filename: filename,
										ep: ep,
										isOffline: isOffline,
										isBGMTVWatched: isBGMTVWatched
									)
							}
							.persistentSystemOverlays(.hidden)
					}
				}
#endif
#if os(tvOS)
					//full screen player
				ZStack {
					let playerObserver = PlayerItemObserver(player: avPlayer)
					VideoPlayerViewiOS(player: avPlayer, playerVM: playerVM, ep: ep)
						.onReceive(playerObserver.$currentStatus) { status in
							playerVM
								.playerObserverHandler(
									status: status,
									bgmItem: bgmItem,
									filename: filename,
									ep: ep,
									isOffline: isOffline,
									isBGMTVWatched: isBGMTVWatched
								)
						}
						.persistentSystemOverlays(.hidden)
				}
#endif
#if os(macOS)
						//player with navbar & webview
				GeometryReader { geometry in
					NavigationView{
						HStack{
							ZStack {
								let playerObserver = PlayerItemObserver(player: avPlayer)
								VideoPlayer(player: avPlayer)
									.onReceive(playerObserver.$currentStatus) { status in
										playerVM
											.playerObserverHandler(
												status: status,
												bgmItem: bgmItem,
												filename: filename,
												ep: ep,
												isOffline: isOffline,
												isBGMTVWatched: isBGMTVWatched
											)
									}

									.navigationTitle(ep?.name ?? "")
									
									.toolbar{
										ToolbarItem(placement: .automatic) {
											Button(action: {
												detailVC?.presentVideoView = false
											}) {
												Text("Close")
											}
										}
									}
							}.frame(maxWidth: .infinity)
							if settingsHandler
								.getShowBgmtvWebWhilePlaying() && (detailVC != nil){
								if let theEP = ep{


									if let bgm_eps_id = theEP.bgm_eps_id{
										let urlString = "https://bgm.tv/ep/\(String(bgm_eps_id))"

										WebView(url: URL(string: urlString)!)
											.ignoresSafeArea()
//											.navigationBarTitleDisplayMode(.inline)
											.frame(width: geometry.size.width*0.2)

									}
								}

							}

						}
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

            }
            
        }
		.onDisappear{
            Task{
				if let player = playerVM.avPlayer{
					player.pause()
					playerVM.logPlaybackPosition(
						player: player,
						bgmItem: bgmItem,
						ep: ep,
						isOffline: isOffline,
						filename: filename,
						isBGMTVWatched: isBGMTVWatched
					)
				}

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
			if let dVM = detailVC{
				if let item = bgmItem{
					dVM.getBGMDetail(id: item.id)
				}
			}

        }


    }

}



//struct VideoPlayerView_Previews: PreviewProvider {
//    static var previews: some View {
//        VideoPlayerView(url: URL(string: "")!, seekTime: 0, ep: EpisodeDetailModel(id: "", bangumi_id: "", bgm_eps_id: 1, name: "", thumbnail: "", status: 1, episode_no: 1, duration: "", bangumi: EPbangumiModel(id: "", bgm_id: 1, name: "", type: 1, status: 1, air_weekday: 1, eps: 1), video_files: [videoFilesListModel(id: "", status: 1, url: "", file_path: "", episode_id: "", bangumi_id: "", duration: 1)]))
//    }
//}
