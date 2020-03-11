//
//  TVVLCPlayerViewController.swift
//  moe.TV
//
//  Created by billgateshxk on 2020/03/12.
//  Copyright © 2020 bi119aTe5hXk. All rights reserved.
//

import UIKit

class TVVLCPlayerViewController: UIViewController {
    var videoURLString: String = ""
    var videoView: UIView!
    var mediaPlayer: VLCMediaPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if videoURLString.lengthOfBytes(using: .utf8) > 0{
            videoView = UIView(frame: view.bounds)
            
            
            mediaPlayer = VLCMediaPlayer()
            mediaPlayer.drawable = view
            mediaPlayer.media = VLCMedia(url: URL(string: videoURLString)!)
            
            mediaPlayer.play()
        }else{
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {

        for press in presses {
            switch press.type {
            case .playPause:
                if mediaPlayer.isPlaying {
                    mediaPlayer.pause()
                }
                else {
                    mediaPlayer.play()
                }
            default: ()
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
}
