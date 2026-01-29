//
//  VideoPlayerView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/14.
//

import AVFoundation
import AVKit
import Combine
import MediaPlayer
import SwiftUI
// TODO: PiP on tvOS & sharePlay & mediacenter
#if os(iOS) || os(tvOS)
    import UIKit
    struct VideoPlayerViewiOS: UIViewControllerRepresentable {
        let player: AVPlayer
        let playerVM: PlayerViewController
        let ep: EpisodeDetailModel?

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
            controller.player?.currentItem?.preferredForwardBufferDuration = TimeInterval(120)
            controller.player?.automaticallyWaitsToMinimizeStalling = true

            if AVPictureInPictureController.isPictureInPictureSupported() {
//            pipController = AVPictureInPictureController(playerLayer: playerLayer)!
                print("canpip")

            } else {
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
                thePlayer.playImmediately(atRate: rate)
                thePlayer.defaultRate = rate
                thePlayer.currentItem?.preferredForwardBufferDuration = TimeInterval(120)
                thePlayer.automaticallyWaitsToMinimizeStalling = true
            }

            setupNowPlayingInfo(player: player)

            return controller
        }

        func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<VideoPlayerViewiOS>) {
            uiViewController.player = player
        }

        func setupNowPlayingInfo(player: AVPlayer) {
            // setup nowplaying
            let item = player.currentItem
            let duration = item?.duration

            var nowPlayingInfo = [String: Any]()
            nowPlayingInfo[MPMediaItemPropertyTitle] = ep?.name ?? ""
            nowPlayingInfo[MPMediaItemPropertyArtist] = ep?.name_cn ?? ""

            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
            //		if let artworkImage = captureArtworkFromVideo(player: player) {
            //			let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in
            //				return artworkImage
            //			}
            //
            //			MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] = artwork
            //		}
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }

        //	func captureArtworkFromVideo(player: AVPlayer) -> UIImage? {
        //		guard let asset = player.currentItem?.asset else { return nil }
        //		let generator = AVAssetImageGenerator(asset: asset)
        //		generator.appliesPreferredTrackTransform = true
//
        //		let time = player.currentTime()
        //		if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
        //			return UIImage(cgImage: cgImage)
        //		}
        //		return nil
        //	}
    }
#endif
// TODO: PiP / playback rate macOS support
// #if os(macOS)
// struct VideoPlayerViewMacOS:NSViewControllerRepresentable{
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
// }
// #endif

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

struct VideoPlayerView: View {
    var url: URL
    var seekTime: Double
    @Binding var bgmItem: BangumiItemModel?
    var ep: EpisodeDetailModel?
    var isOffline: Bool
    var filename: String?
    @StateObject private var playerVM = PlayerViewController()
    var detailVC: BangumiDetailViewController?

    var isBGMTVWatched: Bool

    private let settingsHandler = SettingsHandler()
    
    @StateObject private var playerObserver = PlayerItemObserver()

    @AppStorage("dividerPosition") private var dividerPosition: Double = 0.7 // left
    @GestureState private var dragOffset: CGFloat = 0
    
    private func handleStatus(_ status: AVPlayer.TimeControlStatus?) {
        playerVM.playerObserverHandler(
            status: status,
            bgmItem: bgmItem,
            filename: filename,
            ep: ep,
            isOffline: isOffline,
            isBGMTVWatched: isBGMTVWatched
        )
    }

    var body: some View {
        ZStack {
            if let avPlayer = playerVM.avPlayer {
                #if os(iOS)
                    if settingsHandler
                        .getShowBgmtvWebWhilePlaying() &&
                        (detailVC != nil) &&
                        UIDevice.current.userInterfaceIdiom != .phone {
                        // player with navbar & webview
                        GeometryReader { geometry in
                            let totalWidth = geometry.size.width
                            let leftWidth = max(200, min(totalWidth - 200, totalWidth * CGFloat(dividerPosition) + dragOffset))

                            NavigationView {
                                HStack {
                                    ZStack {
                                        VideoPlayerViewiOS(player: avPlayer, playerVM: playerVM, ep: ep)
                                            .onReceive(playerObserver.$currentStatus, perform: handleStatus)
                                              .onAppear { playerObserver.observe(avPlayer) }
                                            .persistentSystemOverlays(.hidden)
                                    }.frame(width: leftWidth)

                                    Divider()
                                        .frame(width: 10)
                                        .background(Color.gray.opacity(0.2))
                                        .gesture(
                                            DragGesture()
                                                .updating($dragOffset) { value, state, _ in
                                                    state = value.translation.width
                                                }
                                                .onEnded { value in
                                                    let newRatio = (leftWidth + value.translation.width) / totalWidth
                                                    dividerPosition = Double(max(0.2, min(0.8, newRatio)))
                                                }
                                        )
                                        .background(Color.secondary)

                                    if let theEP = ep {
                                        if UIDevice.current.userInterfaceIdiom == .pad {
                                            if let bgm_eps_id = theEP.bgm_eps_id {
                                                let urlString = "https://bgm.tv/ep/\(String(bgm_eps_id))"

                                                WebView(url: URL(string: urlString)!)
                                                    .ignoresSafeArea()
                                                    .navigationBarTitleDisplayMode(.inline)
                                                    .frame(width: totalWidth - leftWidth - 10)
                                                    .navigationTitle("\(ep?.name ?? "") (\(ep?.name_cn ?? "NAME_CN_EMPTY"))")
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
                    } else {
                        // full screen player
                        ZStack {
                            VideoPlayerViewiOS(player: avPlayer, playerVM: playerVM, ep: ep)
                                .onReceive(playerObserver.$currentStatus, perform: handleStatus)
                                  .onAppear { playerObserver.observe(avPlayer) }
                                .persistentSystemOverlays(.hidden)
                        }
                    }
                #endif
                #if os(tvOS)
                    // full screen player
                    ZStack {
                        let playerObserver = PlayerItemObserver(player: avPlayer)
                        VideoPlayerViewiOS(player: avPlayer, playerVM: playerVM, ep: ep)
                            .onReceive(playerObserver.$currentStatus, perform: handleStatus)
                              .onAppear { playerObserver.observe(avPlayer) }
                            .persistentSystemOverlays(.hidden)
                    }
                #endif
                #if os(macOS)
                    // player with navbar & webview
                    GeometryReader { geometry in
                        let totalWidth = geometry.size.width
                        let leftWidth = max(200, min(totalWidth - 200, totalWidth * CGFloat(dividerPosition) + dragOffset))
                        NavigationView {
                            HStack {
                                ZStack {
                                    let playerObserver = PlayerItemObserver(player: avPlayer)
                                    VideoPlayer(player: avPlayer)
                                        .onReceive(playerObserver.$currentStatus, perform: handleStatus)
                                          .onAppear { playerObserver.observe(avPlayer) }

                                        .navigationTitle("\(ep?.name ?? "") (\(ep?.name_cn ?? "NAME_CN_EMPTY"))")

                                        .toolbar {
                                            ToolbarItem(placement: .automatic) {
                                                Button(action: {
                                                    detailVC?.presentVideoView = false
                                                }) {
                                                    Text("Close")
                                                }
                                            }
                                        }
                                }.frame(width: leftWidth)
                                Divider()
                                    .frame(width: 10)
                                    .background(Color.gray.opacity(0.2))
                                    .gesture(
                                        DragGesture()
                                            .updating($dragOffset) { value, state, _ in
                                                state = value.translation.width
                                            }
                                            .onEnded { value in
                                                let newRatio = (leftWidth + value.translation.width) / totalWidth
                                                dividerPosition = Double(max(0.2, min(0.8, newRatio)))
                                            }
                                    )
                                    .background(Color.secondary)

                                if settingsHandler
                                    .getShowBgmtvWebWhilePlaying() && (detailVC != nil) {
                                    if let theEP = ep {
                                        if let bgm_eps_id = theEP.bgm_eps_id {
                                            let urlString = "https://bgm.tv/ep/\(String(bgm_eps_id))"

                                            WebView(url: URL(string: urlString)!)
                                                .ignoresSafeArea()
                                                //											.navigationBarTitleDisplayMode(.inline)
                                                .frame(width: totalWidth - leftWidth - 10)
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
                if UIDevice.current.userInterfaceIdiom == .phone && settingsHandler.getLandscapePlayback() {
                    OrientationController.shared.unlockOrientation()
                    OrientationController.shared.currentOrientation = .landscapeRight
                }
            #endif
            playerVM.loadFromUrl(url: url)
            if let player = playerVM.avPlayer {
                player.currentItem?.preferredForwardBufferDuration = TimeInterval(60)
                player.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
                player.automaticallyWaitsToMinimizeStalling = true

                if seekTime != 0 {
                    print("seekto:\(seekTime)")
                    player.seek(to: CMTime(seconds: seekTime,
                                           preferredTimescale: Int32(NSEC_PER_SEC)),
                                toleranceBefore: CMTime.zero,
                                toleranceAfter: CMTime.zero) { finished in
                        if finished {
                            player.play()
                        }
                    }
                } else {
                    print("seek0")
                }
            }
        }
        .onDisappear {
            Task {
                if let player = playerVM.avPlayer {
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
                if UIDevice.current.userInterfaceIdiom == .phone && settingsHandler.getLandscapePlayback() {
                    //					OrientationController.shared.unlockOrientation()
                    //					OrientationController.shared.currentOrientation = .portrait
                    if let w = SceneDelegate().window {
                        OrientationController.shared.lockOrientation(to: .portrait,
                                                                     onWindow: w)
                    }
                }
            #endif
            if let dVM = detailVC {
                if let item = bgmItem {
                    dVM.getBGMDetail(id: item.id) { _ in
                    }
                }
            }
        }
    }
}

// struct VideoPlayerView_Previews: PreviewProvider {
//    static var previews: some View {
//        VideoPlayerView(url: URL(string: "")!, seekTime: 0, ep: EpisodeDetailModel(id: "", bangumi_id: "", bgm_eps_id: 1, name: "", thumbnail: "", status: 1, episode_no: 1, duration: "", bangumi: EPbangumiModel(id: "", bgm_id: 1, name: "", type: 1, status: 1, air_weekday: 1, eps: 1), video_files: [videoFilesListModel(id: "", status: 1, url: "", file_path: "", episode_id: "", bangumi_id: "", duration: 1)]))
//    }
// }
