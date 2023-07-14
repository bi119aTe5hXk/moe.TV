//
//  PlayerViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/04.
//

import Foundation
import AVKit
import AVFoundation
import MediaPlayer
import Combine

class PlayerViewModel: ObservableObject {
    @Published var avPlayer:AVPlayer?

    func loadFromUrl(url: URL) {
        avPlayer = AVPlayer(url: url)
    }
    
    func logPlaybackPosition(player:AVPlayer, ep:EpisodeDetailModel) {
        let currentItem = player.currentItem;
        let currentTime = CMTimeGetSeconds(currentItem!.currentTime())
        let percent = CMTimeGetSeconds(currentItem!.currentTime()) / CMTimeGetSeconds(currentItem!.duration)
        
        var isFinished = false
        if percent > 0.95{
            isFinished = true
            if let subject_id = ep.bangumi?.bgm_id{
                if let episode_id = ep.bgm_eps_id{
                    updateBGMSBEPwatched(subject_id: subject_id,
                                         episode_id: episode_id) { result, data in
                        print(data)
                    }
                }else{
                    print("ep.bgm_eps_id is missing")
                }
            }else{
                print("ep.bangumi.bgm_id is missing")
            }
            
        }
        print("logprogress:\(currentTime),\(percent)")
        if let bangumi_id = ep.bangumi_id{
            sentEPWatchProgress(ep_id: ep.id,
                                bangumi_id: bangumi_id,
                                last_watch_position: currentTime,
                                percentage: percent,
                                is_finished: isFinished
            ) { result, data in
                print(data as Any)
            }
        }else{
            print("ep.bangumi_id is missing")
        }
        
        //TODO: update bangumi fav status when final ep watched
        if let episode_no  = ep.episode_no{
            if let eps = ep.bangumi?.eps{
                if episode_no == eps{
                    print("should set the subject as watched")
                    
                }
            }
        }
    }
    
    

}

