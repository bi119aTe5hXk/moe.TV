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
        #if os(tvOS)
        return .system
        #else
        return settingsHandler.getUseCustomPlayerUI() ? .custom : .system
        #endif
    }

    private var playerChromeTitle: String? {
        let title = ep?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return title.isEmpty ? nil : title
    }

    private var playerChromeSubtitle: String? {
        let subtitle = ep?.name_cn?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return subtitle.isEmpty ? nil : subtitle
    }

    private var playerChromeCloseAction: (() -> Void)? {
        #if os(tvOS)
        return nil
        #else
        guard detailVC != nil else { return nil }
        return {
            detailVC?.closePlayer()
        }
        #endif
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

    private func clampedSplitPlayerWidth(totalWidth: CGFloat, offset: CGFloat = 0) -> CGFloat {
        guard totalWidth > 0 else { return 0 }
        let minimumPaneWidth = min(200, totalWidth / 2)
        let baseWidth = totalWidth * CGFloat(dividerPosition)
        return max(minimumPaneWidth, min(totalWidth - minimumPaneWidth, baseWidth + offset))
    }

    private func clampedDividerPosition(_ ratio: CGFloat) -> Double {
        Double(max(0.2, min(0.8, ratio)))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let avPlayer = playerVM.avPlayer {
                #if os(iOS)
                    if settingsHandler
                        .getShowBgmtvWebWhilePlaying() &&
                        (detailVC != nil) &&
                        UIDevice.current.userInterfaceIdiom != .phone {
                        // player with navbar & webview
                        GeometryReader { geometry in
                            let totalWidth = geometry.size.width
                            let baseLeftWidth = clampedSplitPlayerWidth(totalWidth: totalWidth)
                            let leftWidth = clampedSplitPlayerWidth(totalWidth: totalWidth, offset: dragOffset)

                            HStack(spacing: 0) {
                                    ZStack {
                                        
                                        PlayerSurfaceView(
                                            player: avPlayer,
                                            ep: ep,
                                            playerVM: playerVM,
                                            observer: playerObserver,
                                            onStatus: handleStatus,
                                            mode: playerSurfaceMode,
                                            title: playerChromeTitle,
                                            subtitle: playerChromeSubtitle,
                                            onClose: playerChromeCloseAction
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
                                                    let newRatio = (baseLeftWidth + value.translation.width) / totalWidth
                                                    dividerPosition = clampedDividerPosition(newRatio)
                                                }
                                        )
                                        .background(Color.secondary)

                                    if let theEP = ep {
                                        if UIDevice.current.userInterfaceIdiom == .pad {
                                            if let bgm_eps_id = theEP.bgm_eps_id {
                                                let urlString = "https://bgm.tv/ep/\(String(bgm_eps_id))"

                                                WebView(url: URL(string: urlString)!, mode:.inlineWK)
                                                    .ignoresSafeArea()
                                                    .frame(width: totalWidth - leftWidth - 10)
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
                                mode: playerSurfaceMode,
                                title: playerChromeTitle,
                                subtitle: playerChromeSubtitle,
                                onClose: playerChromeCloseAction
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
                            mode: playerSurfaceMode,
                            title: playerChromeTitle,
                            subtitle: playerChromeSubtitle,
                            onClose: playerChromeCloseAction
                        )
                            .persistentSystemOverlays(.hidden)
                    }
                #endif
                #if os(macOS)
                    // player with navbar & webview
                    GeometryReader { geometry in
                        let totalWidth = geometry.size.width
                        let baseLeftWidth = clampedSplitPlayerWidth(totalWidth: totalWidth)
                        let leftWidth = clampedSplitPlayerWidth(totalWidth: totalWidth, offset: dragOffset)
                        HStack(spacing: 0) {
                                ZStack {
                                    PlayerSurfaceView(
                                        player: avPlayer,
                                        ep: ep,
                                        playerVM: playerVM,
                                        observer: playerObserver,
                                        onStatus: handleStatus,
                                        mode: playerSurfaceMode,
                                        title: playerChromeTitle,
                                        subtitle: playerChromeSubtitle,
                                        onClose: playerChromeCloseAction
                                    )
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
                                                let newRatio = (baseLeftWidth + value.translation.width) / totalWidth
                                                dividerPosition = clampedDividerPosition(newRatio)
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
                #endif
            }
        }
        .background(Color.black.ignoresSafeArea())
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            PlayerPresentationState.shared.beginPresentation()
            #if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .phone && settingsHandler.getLandscapePlayback() {
                    OrientationController.shared.lockOrientation(to: .landscapeRight)
                }
            #endif
			playerVM.loadFromUrl(url: url, useStreamingCache: !isOffline && !url.isFileURL)
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
                    playerVM.play()
                }
            }
        }
        .onDisappear {
            PlayerPresentationState.shared.endPresentation()
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
                if UIDevice.current.userInterfaceIdiom == .phone {
                    OrientationController.shared.restorePortraitThenUnlock()
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

@MainActor
final class PlayerPresentationState: ObservableObject {
    static let shared = PlayerPresentationState()

    @Published private(set) var isPlayerPresented = false
    private var activePresentationCount = 0

    private init() {}

    func beginPresentation() {
        activePresentationCount += 1
        isPlayerPresented = activePresentationCount > 0
    }

    func endPresentation() {
        activePresentationCount = max(0, activePresentationCount - 1)
        isPlayerPresented = activePresentationCount > 0
    }
}

// struct VideoPlayerView_Previews: PreviewProvider {
//    static var previews: some View {
//        VideoPlayerView(url: URL(string: "")!, seekTime: 0, ep: EpisodeDetailModel(id: "", bangumi_id: "", bgm_eps_id: 1, name: "", thumbnail: "", status: 1, episode_no: 1, duration: "", bangumi: EPbangumiModel(id: "", bgm_id: 1, name: "", type: 1, status: 1, air_weekday: 1, eps: 1), video_files: [videoFilesListModel(id: "", status: 1, url: "", file_path: "", episode_id: "", bangumi_id: "", duration: 1)]))
//    }
// }
