//
//  BangumiDetailViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/04.
//

import Foundation
import SDWebImageSwiftUI

struct NewEPItem:Decodable {
	var ep:BGMEpisode
	var bgmEP:BGMTVUserEpisodeCollectionModel?
}

struct EpisodeScrollRequest: Equatable {
	let id = UUID()
	let episodeID: String
}

class BangumiDetailViewController : ObservableObject {
	private let settingsHandler = SettingsHandler()
	private var pendingPlaybackAfterNotice: (url: String, seekTime: Double, isOffline: Bool, filename: String?)?

	    @Published var presentVideoView = false
	    @Published var presentContinuePlayAlert = false
	    @Published var presentSourceSelectAlert = false
		@Published var presentPlaybackNoticeAlert = false
		@Published var playbackNoticeMessage = ""
    
    @Published var videoURL:String = ""
    @Published var videoIsOffline = false
    @Published var videoFileName:String?
    @Published var seek:Double = 0.0
    @Published var ep:EpisodeDetailModel?
    @Published var detailItem:BangumiDetailModel?
//	@Published var bgmCollectionEpList:[BGMTVUserEpisodeCollectionModel]?
	@Published var newEPList:[NewEPItem] = []
    @Published var albireo_favorite_status:Int?
	@Published var bgmtv_favorite_status:Int?
	@Published var bgmtvCollection: BGMTVUserSubjectCollectionModel?
	@Published private(set) var albireoV2Rating: Int?
	@Published private(set) var albireoV2Comment: String?
	var collectionRating: Int? {
		let bgmRating = bgmtvCollection?.rate ?? 0
		return bgmRating > 0 ? bgmRating : albireoV2Rating
	}
	var collectionComment: String? {
		let bgmComment = bgmtvCollection?.comment?.trimmingCharacters(in: .whitespacesAndNewlines)
		return bgmComment?.isEmpty == false ? bgmComment : albireoV2Comment
	}
	@Published var presentCollectionEditor = false
	@Published private(set) var collectionEditorInitialStatus = 3
	private var pendingCollectionEditorStatus: Int?
	private var playerDismissalComplete = false
	var preferredCollectionStatus: Int {
		[albireo_favorite_status, bgmtv_favorite_status]
			.compactMap { $0 }
			.first(where: { (1...5).contains($0) }) ?? 3
	}

	@Published var isFinished:Bool = true
	@Published var favStatusLoaded:Bool = false
	@Published var selectedID: String? = nil
	@Published var isSelectedFinalEpisode = false
	@Published private(set) var episodeScrollRequest: EpisodeScrollRequest?
    
    var playbackURL: URL? {
        guard !videoURL.isEmpty else { return nil }
        if let url = URL(string: videoURL), url.scheme != nil {
            return url
        }
        return URL(fileURLWithPath: videoURL)
    }
    
    
//	init(){
//		ImageCache().wrappedValue.setCacheLimit(
//			countLimit: 1000, // 1000 items
//			totalCostLimit: 1024 * 1024 * 200 // 200 MB
//		)
//	}

	// MARK: - Prepare Player
    //1 get selected EP
    func setSelectedEP(ep:EpisodeDetailModel){
        DispatchQueue.main.async {
            self.ep = ep
            self.isSelectedFinalEpisode = self.isFinalEpisode(ep)
            self.checkLastWatchPosition(ep: ep)
        }
    }

	private func isFinalEpisode(_ episode: EpisodeDetailModel) -> Bool {
		guard let episodeNumber = episode.episode_no else { return false }
		let knownEpisodeNumbers = newEPList.compactMap(\.ep.episode_no)
		guard let finalEpisodeNumber = knownEpisodeNumbers.max() else { return false }
		return episodeNumber == finalEpisodeNumber
	}
    
    //2 check last position
    func checkLastWatchPosition(ep:EpisodeDetailModel){
        if let watchProgress = ep.watch_progress{
			let percentage = watchProgress.percentage ?? 0
			let lastWatchPosition = watchProgress.last_watch_position ?? 0
			if lastWatchPosition > 0 && percentage > 0 && percentage < 0.95 {
                print("can seek")
                DispatchQueue.main.async {
                    self.presentContinuePlayAlert = true
                }
            }else{
                print("no resumable progress")
                self.checkVideoSource(ep:ep, seekTime: 0)
            }
        }else{
            print("no watchProgress")
            self.checkVideoSource(ep:ep, seekTime: 0)
        }
    }
    
    //3 check video source (ask if more than one source)
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
						self.prepareAndShowVideoView(url: url0, seekTime: seekTime)
	                }else{
	                    print("vFile[0].url is empty!")
	                }
            }else{
                print("ep.video_files is empty!")
            }
        }
    }
		func prepareAndShowVideoView(url: String, seekTime: Double, isOffline: Bool = false, filename: String? = nil) {
			let urlstr = fixPathNotCompete(path: url).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url
			guard !isOffline else {
				showVideoView(url: urlstr, seekTime: seekTime, isOffline: isOffline, filename: filename)
				return
			}

			resolveVideoCDNPlaybackURL(urlstr) { resolvedURL, notice in
				DispatchQueue.main.async {
					if let notice, !notice.isEmpty {
						self.playbackNoticeMessage = notice
						self.pendingPlaybackAfterNotice = (
							url: resolvedURL,
							seekTime: seekTime,
							isOffline: isOffline,
							filename: filename
						)
						self.presentPlaybackNoticeAlert = true
						return
					}
					self.showVideoView(url: resolvedURL, seekTime: seekTime, isOffline: isOffline, filename: filename)
				}
			}
		}

		func continuePendingPlaybackAfterNotice() {
			guard let pendingPlaybackAfterNotice else {
				return
			}
			self.pendingPlaybackAfterNotice = nil
			showVideoView(
				url: pendingPlaybackAfterNotice.url,
				seekTime: pendingPlaybackAfterNotice.seekTime,
				isOffline: pendingPlaybackAfterNotice.isOffline,
				filename: pendingPlaybackAfterNotice.filename
			)
		}

	    //4 start playback
	    func showVideoView(url:String, seekTime:Double, isOffline: Bool = false, filename: String? = nil) {
        DispatchQueue.main.async {
			self.playerDismissalComplete = false
            self.presentVideoView = false
            self.seek = seekTime
            self.videoURL = url
            self.videoIsOffline = isOffline
            self.videoFileName = filename
            self.presentContinuePlayAlert = false
            self.presentSourceSelectAlert = false
            DispatchQueue.main.async {
                self.presentVideoView = true
            }
        }
    }
    
    
    
	func closePlayer() {
		DispatchQueue.main.async {
			self.presentVideoView = false
			self.videoURL = ""
			self.videoIsOffline = false
			self.videoFileName = nil
		}
	}

	func playerDidDismiss() {
		playerDismissalComplete = true
		if let selectedID {
			episodeScrollRequest = EpisodeScrollRequest(episodeID: selectedID)
		}
		videoURL = ""
		videoIsOffline = false
		videoFileName = nil
		if let status = pendingCollectionEditorStatus {
			pendingCollectionEditorStatus = nil
			DispatchQueue.main.async {
				self.showCollectionEditor(defaultStatus: status)
			}
		}
	}

	func showCollectionEditor(defaultStatus: Int) {
		collectionEditorInitialStatus = (1...5).contains(defaultStatus) ? defaultStatus : 3
		presentCollectionEditor = true
	}

	func queueCollectionEditorAfterPlayback() {
		if playerDismissalComplete {
			DispatchQueue.main.async {
				self.showCollectionEditor(defaultStatus: 2)
			}
		} else {
			pendingCollectionEditorStatus = 2
		}
	}

	func saveCollection(
		status: Int,
		rating: Int?,
		comment: String?,
		completion: @escaping (Bool, String?) -> Void
	) {
		guard let item = detailItem else {
			completion(false, "Bangumi detail is unavailable.")
			return
		}

		settingsHandler.registerSettings()
		let isV2 = settingsHandler.getAlbireoAuthMode() == .albireoV2OAuth
		let shouldUpdateBGMTV = isBGMTVlogined()
		let review = comment?.trimmingCharacters(in: .whitespacesAndNewlines)
		changeAlbireoFavStatus(
			bangumi_id: item.id,
			status: status,
			rating: isV2 ? rating : nil,
			review: isV2 ? review : nil
		) { albireoSuccess, albireoResult in
			DispatchQueue.main.async {
				if albireoSuccess {
					self.albireo_favorite_status = status
					if isV2 {
						if let rating { self.albireoV2Rating = rating }
						if let review { self.albireoV2Comment = review.isEmpty ? nil : review }
					}
				}
			}
			guard shouldUpdateBGMTV else {
				DispatchQueue.main.async {
					completion(albireoSuccess, albireoSuccess ? nil : "Albireo: \(String(describing: albireoResult))")
				}
				return
			}
			guard let bgmID = item.bgm_id else {
				DispatchQueue.main.async {
					completion(false, "bgm.tv subject ID is unavailable.")
				}
				return
			}
			setBGMCollectionStatus(subject_id: bgmID, status: status, rating: rating, comment: review) { bgmSuccess, bgmResult in
				DispatchQueue.main.async {
					if bgmSuccess {
						self.bgmtv_favorite_status = status
						self.getBGMTVFAVStatus(item: item) { _, _ in }
					}
					let failures = [
						albireoSuccess ? nil : "Albireo: \(String(describing: albireoResult))",
						bgmSuccess ? nil : "bgm.tv: \(String(describing: bgmResult))"
					].compactMap { $0 }
					completion(failures.isEmpty, failures.isEmpty ? nil : failures.joined(separator: "\n"))
				}
			}
		}
	}

	// MARK: - Bangumi Detail
	func getBGMDetail(id:String, completion: @escaping (Bool) -> Void) {
		print("getBGMDetail:\(id)")
		self.selectedID = nil
		self.detailItem = nil
        self.albireo_favorite_status = nil
        self.bgmtv_favorite_status = nil
		self.bgmtvCollection = nil
		self.albireoV2Rating = nil
		self.albireoV2Comment = nil
		self.newEPList = []
		self.isFinished = false
        self.favStatusLoaded = false
		settingsHandler.registerSettings()
		if settingsHandler.getAlbireoAuthMode() == .albireoV2OAuth {
			getAlbireoV2BangumiDetail(id: id) { isSuccessed, data in
				if !isSuccessed {
					DispatchQueue.main.async {
						self.isFinished = true
						self.favStatusLoaded = true
					}
					print("Albireo V2 bangumi detail failed: \(data)")
					completion(false)
					return
				}

				guard let bgmItem = data as? BangumiDetailModel else {
					DispatchQueue.main.async {
						self.isFinished = true
						self.favStatusLoaded = true
					}
					print("Albireo V2 bangumi detail response has unexpected type: \(data)")
					completion(false)
					return
				}

				let episodes = bgmItem.episodes ?? []
				DispatchQueue.main.async {
					self.detailItem = bgmItem
					self.albireo_favorite_status = bgmItem.favorite_status ?? 0
				}

				if isBGMTVlogined() {
					self.getBGMTVFAVStatus(item: bgmItem) { isSuccessed, result in
						DispatchQueue.main.async {
							self.bgmtv_favorite_status = isSuccessed ? result : 0
							self.favStatusLoaded = true
						}
					}

					if let bgmID = bgmItem.bgm_id {
						self.getBGMTVEPList(
							bgmID: bgmID,
							epList: episodes
						)
					} else {
						print("bgmId/bgm_id is empty")
						DispatchQueue.main.async {
							self.showOnlyAlbireoEPs(eps: episodes)
							self.favStatusLoaded = true
						}
					}
					completion(true)
					return
				}

				DispatchQueue.main.async {
					self.bgmtv_favorite_status = 0
					self.favStatusLoaded = true
					self.showOnlyAlbireoEPs(eps: episodes)
					completion(true)
				}
			}
			return
		}

        getAlbireoBangumiDetail(id: id) { isSuccessed, data in
            if !isSuccessed{
                self.isFinished = true
                print("Finished: no bangumi detail")
                return
            }
			if let bgmItem = data as? BangumiDetailModel{
				DispatchQueue.main.async {
					self.detailItem = bgmItem
					if bgmItem.item_id == nil {
						self.resolveBoxItemID(for: bgmItem.id)
					}
					if let favStatus = bgmItem.favorite_status{
						self.albireo_favorite_status = favStatus
					}else{
						self.albireo_favorite_status = 0
					}
				}

				if isBGMTVlogined(){
					//get fav status from bgm.tv
					self.getBGMTVFAVStatus(item: bgmItem){ isSuccessed, result in
						DispatchQueue.main.async {
							if !isSuccessed{
								self.bgmtv_favorite_status = 0
                                self.favStatusLoaded = true
								return
							}
							self.bgmtv_favorite_status = result
                            self.favStatusLoaded = true
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
					DispatchQueue.main.async {
						self.bgmtv_favorite_status = 0
						self.favStatusLoaded = true
						self.showOnlyAlbireoEPs(eps: bgmItem.episodes ?? [])
					}
				}



            }
			completion(true)
        }

    }

	private struct BoxItemReference: Decodable {
		let itemId: UUID?
	}

	private func resolveBoxItemID(for bangumiID: String) {
		guard UUID(uuidString: bangumiID) != nil,
			let server = validatedHTTPServerURL(settingsHandler.getAlbireoServerAddr()),
			let baseURL = URL(string: server) else { return }
		let url = baseURL
			.appendingPathComponent("api")
			.appendingPathComponent("v2")
			.appendingPathComponent("bangumi")
			.appendingPathComponent(bangumiID)
		URLSession.shared.dataTask(with: url) { data, response, _ in
			guard let response = response as? HTTPURLResponse,
				response.statusCode == 200,
				let data,
				let itemID = try? JSONDecoder().decode(BoxItemReference.self, from: data).itemId else { return }
			DispatchQueue.main.async {
				guard self.detailItem?.id == bangumiID else { return }
				self.detailItem?.item_id = itemID.uuidString
			}
		}.resume()
	}

	func getBGMTVFAVStatus(item:BangumiDetailModel ,completion: @escaping (Bool, Int) -> Void){
			if let bgmid = item.bgm_id{
				getBGMCollectionStatus(subject_id: bgmid) { result, data in
					print("getBGMTVFAVStatus:\(data)")
					if result{
						if let r = data as? BGMTVUserSubjectCollectionModel{
							DispatchQueue.main.async {
								if self.detailItem?.id == item.id {
									self.bgmtvCollection = r
								}
							}
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
	}

	@MainActor
	func updatePlaybackProgress(epID: String, snapshot: PlaybackProgressSnapshot) {
		guard let index = newEPList.firstIndex(where: { $0.ep.id == epID }) else { return }

		var item = newEPList[index]
		var progress = item.ep.watch_progress ?? watchProgress(
			id: epID,
			user_id: nil,
			last_watch_position: nil,
			bangumi_id: item.ep.bangumi_id,
			watch_status: nil,
			episode_id: epID,
			percentage: nil
		)
		progress.last_watch_position = snapshot.position
		progress.percentage = Float(snapshot.percentage)
		let wasAlreadyFinished = progress.watch_status == 2
		progress.watch_status = wasAlreadyFinished || snapshot.isFinished ? 2 : 3
		item.ep.watch_progress = progress
		if snapshot.isFinished, let bgmEP = item.bgmEP {
			item.bgmEP = BGMTVUserEpisodeCollectionModel(
				episode: bgmEP.episode,
				type: 2
			)
		}
		newEPList[index] = item

		if ep?.id == epID {
			ep?.watch_progress = progress
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
                        self.isFinished = true
                        print("Finished: getBGMCollectionEpisodeList")
					}
                    
                    
				}else{
					print( "data is not BGMTVCollectionEpisodesModel")
					self.showOnlyAlbireoEPs(eps: epList)
				}
			}else{
				print("getBGMCollectionEpisodeList failed")
				DispatchQueue.main.async {
					self.showOnlyAlbireoEPs(eps: epList)
				}
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
		let update = {
			self.newEPList.removeAll()
			self.newEPList = self.combineEPList(
				eps: eps,
				bgmEPs: []
			)
			self.isFinished = true
            print("Finished: showOnlyAlbireoEPs")
		}
		if Thread.isMainThread {
			update()
		} else {
			DispatchQueue.main.async(execute: update)
		}
	}

	func isBGMEPWatched() -> Bool{
		if self.bgmtv_favorite_status == 2{
			return true
		}
		return false
	}

    
}
