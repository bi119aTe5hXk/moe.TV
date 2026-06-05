//
//  VideoPlayerView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/14.
//

import AVFoundation
import AVKit

import MediaPlayer
import SwiftUI
#if !os(tvOS)
import WebKit
#endif


struct VideoPlayerView: View {
    var url: URL
    var seekTime: Double
    @Binding var bgmItem: BangumiItemModel?
    var ep: EpisodeDetailModel?
    var isOffline: Bool
    var filename: String?
    @StateObject private var playerVM = PlayerViewController()
    var detailVC: BangumiDetailViewController?
	
	private let streamingFactory = StreamingPlayerItemFactory()

    var isBGMTVWatched: Bool

    private let settingsHandler = SettingsHandler()
    
    @StateObject private var playerObserver = PlayerItemObserver()

    @AppStorage("dividerPosition") private var dividerPosition: Double = 0.7 // left
    @GestureState private var dragOffset: CGFloat = 0
    
    private var playerSurfaceMode: PlayerSurfaceMode {
        settingsHandler.getUseCustomPlayerUI() ? .custom : .system
    }

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
                                        
                                        PlayerSurfaceView(
                                            player: avPlayer,
                                            ep: ep,
                                            playerVM: playerVM,
                                            observer: playerObserver,
                                            onStatus: handleStatus,
                                            mode: playerSurfaceMode
                                        )
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

                                                WebView(url: URL(string: urlString)!, mode:.inlineWK)
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
                            PlayerSurfaceView(
                                player: avPlayer,
                                ep: ep,
                                playerVM: playerVM,
                                observer: playerObserver,
                                onStatus: handleStatus,
                                mode: playerSurfaceMode
                            )
                                .persistentSystemOverlays(.hidden)
                        }
                    }
                #endif
                #if os(tvOS)
                    // full screen player
                    ZStack {
                        PlayerSurfaceView(
                            player: avPlayer,
                            ep: ep,
                            playerVM: playerVM,
                            observer: playerObserver,
                            onStatus: handleStatus,
                            mode: playerSurfaceMode
                        )
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
                                    PlayerSurfaceView(
                                        player: avPlayer,
                                        ep: ep,
                                        playerVM: playerVM,
                                        observer: playerObserver,
                                        onStatus: handleStatus,
                                        mode: playerSurfaceMode
                                    )

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
                                            WebView(url: URL(string: urlString)!, mode: .inlineWK)
                                                .ignoresSafeArea()
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
			playerVM.loadFromUrl(url: url, useStreamingCache: true)
            if let player = playerVM.avPlayer {
                player.currentItem?.preferredForwardBufferDuration = TimeInterval(120)
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
					streamingFactory.stop(deleteCache: false)
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
