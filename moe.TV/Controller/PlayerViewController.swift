//
//  PlayerViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/04.
//

import Foundation
import AVKit
import AVFoundation
import MediaPlayer
import Combine

class PlayerViewController: ObservableObject {
    @Published var avPlayer:AVPlayer?
    let offlinePBM = OfflinePlaybackManager()

	var settingsHandler = SettingsHandler()

    func loadFromUrl(url: URL) {
		print("\(url)")
        avPlayer = AVPlayer(url: url)
    }

	func playerObserverHandler(
		status:AVPlayer.TimeControlStatus?,
		bgmItem:BangumiItemModel?,
		filename:String?,
		ep:EpisodeDetailModel?,
		isOffline:Bool,
		isBGMTVWatched:Bool
	){
		switch status{
			case nil:
				print("nothing is here")
			case .waitingToPlayAtSpecifiedRate:
				print("waiting")
			case .paused:
				print("paused")
				if let player = avPlayer {
					logPlaybackPosition(player: player,
										bgmItem: bgmItem,
										ep: ep,
										isOffline: isOffline,
										filename: filename,
										isBGMTVWatched: isBGMTVWatched)
				}
			case .playing:
				print("playing")
			case .some(_):
				print("unknown player status:\(String(describing: status))")
			@unknown default:
				print("unknown player status:\(String(describing: status))")
		}
	}

    func logPlaybackPosition(player:AVPlayer,
							 bgmItem:BangumiItemModel?,
                             ep:EpisodeDetailModel?,
                             isOffline:Bool,
                             filename:String?,
							 isBGMTVWatched:Bool) {
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
				if isFinished && !isBGMTVWatched{
                    if let subject_id = theEP.bangumi?.bgm_id{
                        if let episode_id = theEP.bgm_eps_id{
							print("save to BGM.TV as watched")
                            setBGMSBEPStatues(subject_id: subject_id,
                                                 episode_id: episode_id,
                                                 status: 2) { result, data in
                                print(data)
                            }
                        }else{
                            print("ep.bgm_eps_id is missing")
                        }
                    }else{
                        print("ep.bangumi.bgm_id is missing")
                    }
                }

				if let bangumi_id = theEP.bangumi_id{
					print("save progress to albireo")
					sentAlbireoEPWatchProgress(ep_id: theEP.id,
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

				if let item = bgmItem{
						//save to playback history
					savePlaybackHistory(item)

						//set watched when finish final ep
					if settingsHandler.getSetWatchedWhenFinishedFinalEP() && isFinished{
							//check is the final ep
						if let episode_no  = theEP.episode_no{
							if let eps = theEP.bangumi?.eps{
								if episode_no == eps{
									print("should set the subject/collection as watched: episode_no:\(episode_no),eps:\(eps)")
										//only do auto set when fav status is watching
										//TODO: check bgm.tv fav status
									if item.favorite_status == 3{
										changeFavStatus(
											idstr: item.id,
											bgmid: item.bgm_id,
											status: 2
										)
									}else{
										print("fav status is not watching. skip set as watched")
									}
								}
							}
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

	func setMatadata(ep:EpisodeDetailModel?) -> [AVMetadataItem] {
		var metadata: [AVMetadataItem] = []
		guard let ep else { return metadata }

		if let name = ep.name {
			metadata.append(createMetadataItem(for: .commonIdentifierTitle, value: name))
		}
		if let summary = ep.summary {
			metadata.append(createMetadataItem(for: .commonIdentifierDescription, value: summary))
		}
		if let imageURL = ep.thumbnail {
			let url = URL(string: imageURL)!
			let rdata = try? Data(contentsOf: url)
			metadata
				.append(
					createMetadataItem(
						for: .commonIdentifierArtwork,
						value: rdata ?? NSNull()
					)
				)


		}
		if let subtitle = ep.name_cn {
			metadata.append(createMetadataItem(for: .iTunesMetadataTrackSubTitle,value: subtitle))
		}

		return metadata
	}

	private func createMetadataItem(for identifier: AVMetadataIdentifier,
									value: Any) -> AVMetadataItem {
		let item = AVMutableMetadataItem()
		item.identifier = identifier
		item.value = value as? NSCopying & NSObjectProtocol
			// Specify "und" to indicate an undefined language.
		item.extendedLanguageTag = "und"
		return item.copy() as! AVMetadataItem
	}

	func changeFavStatus(idstr:String?, bgmid:Int?, status:Int) {
		if let idstr1 = idstr {
			print("changing fav status to \(status)")
			changeAlbireoFavStatus(bangumi_id: idstr1, status: status, completion: { isSuccess, result in
				print(result as Any)
				if isSuccess {
					print("albireo fav status change success")
				}
			})
		}


		if let bgm_id = bgmid{
			setBGMCollectionStatus(subject_id: bgm_id, status: status) { isSuccess, result in
				print(result as Any)
				if isSuccess {
					print("setBGMCollectionStatus success")
				}else{
					print("setBGMCollectionStatus retrun false")
				}
			}
		}else{
			print("bgmid not found")
		}
	}
}

