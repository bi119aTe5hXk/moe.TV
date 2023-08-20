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
    let offlinePBM = OfflinePlaybackManager()

    func loadFromUrl(url: URL) {
        avPlayer = AVPlayer(url: url)
    }
    
    func logPlaybackPosition(player:AVPlayer,
                             ep:EpisodeDetailModel?,
                             isOffline:Bool,
                             filename:String?) {
        let currentItem = player.currentItem;
        let currentTime = CMTimeGetSeconds(currentItem!.currentTime())
        var percent = CMTimeGetSeconds(currentItem!.currentTime()) / CMTimeGetSeconds(currentItem!.duration)
        if percent.isNaN{
            percent = 0
        }
        print("logprogress:\(currentTime),\(percent)")
        
        var isFinished = false
        if percent > 0.95{
            isFinished = true
        }
        
        
        if !isOffline{
            if let theEP = ep {
                if let subject_id = theEP.bangumi?.bgm_id{
                    if let episode_id = theEP.bgm_eps_id{
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
                
                
                if let bangumi_id = theEP.bangumi_id{
                    sentEPWatchProgress(ep_id: theEP.id,
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
                if let episode_no  = theEP.episode_no{
                    if let eps = theEP.bangumi?.eps{
                        if episode_no == eps{
                            print("should set the subject as watched")
                            
                        }
                    }
                }
            }
            
        }else{
            if let theFileName = filename{
                print("loging offline, filename is \(theFileName)")
                offlinePBM.setPlayBackStatus(item: OfflineVideoItem(epID: ep?.id ?? nil,
                                                                    bgm_eps_id: ep?.bgm_eps_id ?? nil,
                                                                    filename: theFileName,
                                                                    position: currentTime,
                                                                    isFinished: isFinished))
            }
        }
    }
    
}

