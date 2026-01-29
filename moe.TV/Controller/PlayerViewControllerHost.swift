//
//  PlayerViewControllerHost.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2026/01/29.
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

        let rate = Float(settingsHandler.getPlaybackRate())
        //        print("rate: \(rate)")
        if let thePlayer = controller.player {
            thePlayer.playImmediately(atRate: rate)
            thePlayer.defaultRate = rate
            thePlayer.currentItem?.preferredForwardBufferDuration = TimeInterval(120)
            thePlayer.automaticallyWaitsToMinimizeStalling = true
        }

        NowPlayingManager.shared.start(player: player, ep: ep)

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: UIViewControllerRepresentableContext<VideoPlayerViewiOS>) {
        uiViewController.player = player
        NowPlayingManager.shared.updateMetadata(ep: ep)
    }

    func setupNowPlayingInfo(player: AVPlayer) {
        // Keep for backward compatibility; prefer NowPlayingManager.
        NowPlayingManager.shared.start(player: player, ep: ep)
    }

    //    func captureArtworkFromVideo(player: AVPlayer) -> UIImage? {
    //        guard let asset = player.currentItem?.asset else { return nil }
    //        let generator = AVAssetImageGenerator(asset: asset)
    //        generator.appliesPreferredTrackTransform = true
//
    //        let time = player.currentTime()
    //        if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
    //            return UIImage(cgImage: cgImage)
    //        }
    //        return nil
    //    }
}
#endif
// TODO: PiP / playback rate macOS support
// #if os(macOS)
// struct VideoPlayerViewMacOS:NSViewControllerRepresentable{
//    typealias NSViewControllerType = NSViewController
//    let player: AVPlayer
//    func makeNSViewController(context: Context) -> NSViewController {
//        let controller = AVPlayerViewController()
//        return controller
//    }
//
//    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
//
//    }
// }
// #endif
