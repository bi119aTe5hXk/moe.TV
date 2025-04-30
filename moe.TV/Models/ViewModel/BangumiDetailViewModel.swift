//
//  BangumiDetailViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/04.
//

import Foundation
import CachedAsyncImage

struct NewEPItem:Decodable {
	var ep:BGMEpisode
	var bgmEP:BGMTVUserEpisodeCollectionModel?
}

class BangumiDetailViewModel : ObservableObject {
    @Published var presentVideoView = false
    @Published var presentContinuePlayAlert = false
    @Published var presentSourceSelectAlert = false
    @Published var videoURL:String = ""
    @Published var seek:Double = 0.0
    @Published var ep:EpisodeDetailModel?
    @Published var detailItem:BangumiDetailModel?
//	@Published var bgmCollectionEpList:[BGMTVUserEpisodeCollectionModel]?
	@Published var newEPList:[NewEPItem] = []
    @Published var albireo_favorite_status:Int?
	@Published var bgmtv_favorite_status:Int?

	init(){
		ImageCache().wrappedValue.setCacheLimit(
			countLimit: 1000, // 1000 items
			totalCostLimit: 1024 * 1024 * 200 // 200 MB
		)
	}

    //1
    func setSelectedEP(ep:EpisodeDetailModel){
        DispatchQueue.main.async {
            self.ep = ep
            self.checkLastWatchPosition(ep: ep)
        }
    }
    
    //2
    func checkLastWatchPosition(ep:EpisodeDetailModel){
        if let watchProgress = ep.watch_progress{
            if watchProgress.percentage != 0 ||
                watchProgress.percentage != 1{
                print("can seek")
                DispatchQueue.main.async {
                    self.presentContinuePlayAlert = true
                }
            }else{
                print("percentage 0 or 1")
                self.checkVideoSource(ep:ep, seekTime: 0)
            }
        }else{
            print("no watchProgress")
            self.checkVideoSource(ep:ep, seekTime: 0)
        }
    }
    
    //3
    func checkVideoSource(ep:EpisodeDetailModel,seekTime:Double){
        self.seek = seekTime
        if (ep.video_files ?? []).count > 1{
            print("more than one source")
            DispatchQueue.main.async {
                self.presentSourceSelectAlert = true
            }
            
        }else{
            if let vFile = ep.video_files{
                if let url0 = vFile[0].url{
                    let urlstr = fixPathNotCompete(path: url0).addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed)!
                    self.showVideoView(url: urlstr, seekTime: seekTime)
                }else{
                    print("vFile[0].url is empty!")
                }
            }else{
                print("ep.video_files is empty!")
            }
        }
    }
    
    
    
    //4
    func showVideoView(url:String, seekTime:Double) {
        DispatchQueue.main.async {
            self.seek = seekTime
            self.videoURL = url
            self.presentContinuePlayAlert = false
            self.presentSourceSelectAlert = false
            self.presentVideoView = true
        }
    }
    
    
    
    func closePlayer(){
        DispatchQueue.main.async {
            self.presentVideoView = false
        }
    }
    
    
    func getBGMDetail(id:String){
        print("getBGMDetail:\(id)")
		self.detailItem = nil
		self.newEPList = []
        getAlbireoBangumiDetail(id: id) { isSuccessed, data in
            if !isSuccessed{
                return
            }
            if let bgmItem = data as? BangumiDetailModel{
				self.detailItem = bgmItem
				DispatchQueue.main.async {
					if let favStatus = bgmItem.favorite_status{
						self.albireo_favorite_status = favStatus
					}else{
						self.albireo_favorite_status = 0
					}

				}

				if isBGMTVlogined(){
					//get fav status from bgm.tv
					self.getBGMTVFAVStatus { isSuccessed, result in
						DispatchQueue.main.async {
							if !isSuccessed{
								self.bgmtv_favorite_status = 0
								return
							}
							self.bgmtv_favorite_status = result
						}
					}

					//get EP list from bgm.tv
					if let bgmID = bgmItem.bgm_id{
						self.getBGMTVEPList(
							bgmID: bgmID,
							epList: bgmItem
								.episodes ?? [])
					}else{
						print("bgm_id is empty")
						self.showOnlyAlbireoEPs(eps: bgmItem.episodes ?? [])
					}
				}else{
					//only albireo eps
					self.showOnlyAlbireoEPs(eps: bgmItem.episodes ?? [])
				}


            }
        }

    }

	func getBGMTVFAVStatus(completion: @escaping (Bool, Int) -> Void){
		if let item = detailItem{
			if let bgmid = item.bgm_id{
				getBGMCollectionStatus(subject_id: bgmid) { result, data in
					print("getBGMTVFAVStatus:\(result as Any)")
					if result{
						if let r = data as? BGMTVUserSubjectCollectionModel{
							completion(true , r.type)
						}else {
							print("result is not BGMTVUserSubjectCollectionModel")
							completion(false , 0)
						}
					} else {
						print("getBGMCollectionStatus return not success")
						completion(false , 0)
					}
				}
			}else{
				print("bgm_id is nil")
				completion(false , 0)
			}
		}else{
			print( "detailItem is nil")
			completion(false , 0)
		}
	}

	func getBGMTVEPList(bgmID:Int,epList:[BGMEpisode]){
		if bgmID == 0{
			print("bgmID is 0")
			return
		}
		getBGMCollectionEpisodeList(subject_id: bgmID) { result, data in
			if result{
				if let r = data as? BGMTVCollectionEpisodesModel{
//					self.bgmCollectionEpList = r.data
					DispatchQueue.main.async {
						self.newEPList.removeAll()
						self.newEPList = self
							.combineEPList(
								eps: epList,
								bgmEPs: r.data ?? []
							)
					}
				}else{
					print( "data is not BGMTVCollectionEpisodesModel")
					self.showOnlyAlbireoEPs(eps: epList)
				}
			}else{
				print("getBGMCollectionEpisodeList failed")
				self.showOnlyAlbireoEPs(eps: epList)
			}
		}
	}

	func combineEPList(eps:[BGMEpisode],
					   bgmEPs:[BGMTVUserEpisodeCollectionModel]) -> [NewEPItem]{

		var combinedArray:[NewEPItem] = []
		for (index, ep) in eps.enumerated() {
			if index >= bgmEPs.count {
				combinedArray.append(NewEPItem(ep: ep, bgmEP: nil))
			}else{
				combinedArray.append(NewEPItem(ep: ep, bgmEP: bgmEPs[index]))
			}
		}
		return combinedArray
	}

	func showOnlyAlbireoEPs(eps:[BGMEpisode]){
		print("showOnlyAlbireoEPs")
		self.newEPList.removeAll()
		DispatchQueue.main.async {
			self.newEPList = self.combineEPList(
				eps: eps,
				bgmEPs: []
			)
		}
	}

	func isBGMEPWatched() -> Bool{
		if self.bgmtv_favorite_status == 2{
			return true
		}
		return false
	}

}
