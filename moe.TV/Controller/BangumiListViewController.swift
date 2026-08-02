//
//  BangumiListViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/09.
//

import Foundation


class BangumiListViewController: ObservableObject{
    @Published var bgmList = [BangumiItemModel]()
    @Published var isLoading = false
	@Published var isLoadingNextPage = false
    @Published var searchText = ""
    @Published var showLogoutAlert = false

    private let settingsHandler = SettingsHandler()
	private let albireoV2PageSize = 24
	private var albireoV2CurrentFunc: FuncViewModel?
	private var albireoV2CurrentSearchKeyword = ""
	private var albireoV2NextOffset = 0
	private var albireoV2CanLoadMore = false

    private func updateBGMList(list:[BangumiItemModel]){
        print("setting \(list.count) objects")
        
        DispatchQueue.main.async {
            self.isLoading = false
            self.bgmList = list
        }
    }
    
    
    func getBGMList(funcType:FuncViewModel?, searchKeyword:String){
        if let type = funcType{
			settingsHandler.registerSettings()
			DispatchQueue.main.async {
				self.isLoading = true
				self.isLoadingNextPage = false
				self.bgmList = []
			}
            isAlbireoLoginValid { result in
                if result{
					if self.settingsHandler.getAlbireoAuthMode() == .albireoV2OAuth {
						self.resetAlbireoV2Pagination(funcType: type, searchKeyword: searchKeyword)
						self.getAlbireoV2DebugList(funcType: type, searchKeyword: searchKeyword)
						return
					}
                    switch type {
                    case .mybangumi:
                        print("BangumiListViewModel.getMyBGMList")
                        getAlbireoMyBangumiList { result, data in
                            self.resultHandler(result: result, data: data, saveTopShelf: true)
                        }
                        return
                    case .onair:
                        print("BangumiListViewModel.getOnAirBGMList")
                        getAlbireoOnAirList { result, data in
                            self.resultHandler(result: result, data: data, saveTopShelf: false)
                        }
                        return
					case .history:
						print("BangumiListViewModel.getHistoryBGMList")
						self.resultHandler(result: true, data: readPlaybackHistory(), saveTopShelf: false)
						return
                    case .search:
                        DispatchQueue.main.async {
                            self.isLoading = false
                            //self.bgmList = []
                        }
                        getAlbireoAllBangumiList(page: 1, name: searchKeyword) { result, data in
                            self.resultHandler(result: result, data: data, saveTopShelf: false)
                        }
                        return
                    case .allbangumi:
                        getAlbireoAllBangumiList(page: 1, name: "") { result, data in
                            self.resultHandler(result: result, data: data, saveTopShelf: false)
                        }
                        return
                    }
                }else{
                    print("Albireo login info error. Cookie expired?")
					DispatchQueue.main.async {
						self.isLoading = false
						self.bgmList = []
						self.showLogoutAlert = true
					}
                }
            }
            
		}
	}

	func loadNextPageIfNeeded(currentItem: BangumiItemModel?) {
		guard settingsHandler.getAlbireoAuthMode() == .albireoV2OAuth,
			  albireoV2CanLoadMore,
			  isLoading == false,
			  isLoadingNextPage == false,
			  let funcType = albireoV2CurrentFunc,
			  funcType == .allbangumi || funcType == .search,
			  let currentItem,
			  bgmList.last?.id == currentItem.id else {
			return
		}

		loadAlbireoV2BangumiPage(funcType: funcType, searchKeyword: albireoV2CurrentSearchKeyword, append: true)
	}

	private func resetAlbireoV2Pagination(funcType: FuncViewModel, searchKeyword: String) {
		albireoV2CurrentFunc = funcType
		albireoV2CurrentSearchKeyword = searchKeyword
		albireoV2NextOffset = 0
		albireoV2CanLoadMore = false
	}
    
	private func getAlbireoV2DebugList(funcType: FuncViewModel, searchKeyword: String) {
		let completion: (Bool, Any) -> Void = { result, data in
			DispatchQueue.main.async {
				guard self.albireoV2CurrentFunc == funcType,
					  self.albireoV2CurrentSearchKeyword == searchKeyword else {
					print("Ignoring stale Albireo V2 \(funcType) list response")
					return
				}

				guard result else {
					self.isLoading = false
					self.bgmList = []
					print("Albireo V2 list request failed: \(data)")
					return
				}

				guard let list = data as? [BangumiItemModel] else {
					self.isLoading = false
					self.bgmList = []
					print("Albireo V2 list response has unexpected type: \(type(of: data))")
					return
				}

				if let firstItem = list.first {
					print("Albireo V2 decoded list count: \(list.count), first: \(firstItem.id), \(firstItem.name ?? ""), favorite_status: \(String(describing: firstItem.favorite_status)), unwatched: \(firstItem.unwatched_count ?? 0)")
				} else {
					print("Albireo V2 decoded list count: 0")
				}
				self.isLoading = false
				self.bgmList = list
			}
		}

		switch funcType {
		case .mybangumi:
			getAlbireoV2FavoriteList(status: .watching, completion: completion)
		case .onair:
			getAlbireoV2OnAirList(completion: completion)
		case .history:
			self.resultHandler(result: true, data: readPlaybackHistory(), saveTopShelf: false)
		case .search:
			loadAlbireoV2BangumiPage(funcType: funcType, searchKeyword: searchKeyword, append: false)
		case .allbangumi:
			loadAlbireoV2BangumiPage(funcType: funcType, searchKeyword: searchKeyword, append: false)
		}
	}

	private func loadAlbireoV2BangumiPage(funcType: FuncViewModel, searchKeyword: String, append: Bool) {
		DispatchQueue.main.async {
			if append {
				self.isLoadingNextPage = true
			} else {
				self.isLoading = true
			}
		}

		getAlbireoV2BangumiList(
			keyword: searchKeyword,
			offset: append ? albireoV2NextOffset : 0,
			limit: albireoV2PageSize
		) { result, data in
			guard result else {
				DispatchQueue.main.async {
					self.isLoading = false
					self.isLoadingNextPage = false
				}
				print("Albireo V2 paged bangumi request failed: \(data)")
				return
			}

			guard let list = data as? [BangumiItemModel] else {
				DispatchQueue.main.async {
					self.isLoading = false
					self.isLoadingNextPage = false
				}
				print("Albireo V2 paged bangumi response has unexpected type: \(data)")
				return
			}

			DispatchQueue.main.async {
				if append {
					let existingIDs = Set(self.bgmList.map { $0.id })
					self.bgmList.append(contentsOf: list.filter { existingIDs.contains($0.id) == false })
				} else {
					self.bgmList = list
				}
				self.albireoV2NextOffset = (append ? self.albireoV2NextOffset : 0) + list.count
				self.albireoV2CanLoadMore = list.count >= self.albireoV2PageSize
				self.isLoading = false
				self.isLoadingNextPage = false
				print("Albireo V2 loaded page count: \(list.count), total: \(self.bgmList.count), canLoadMore: \(self.albireoV2CanLoadMore)")
			}
		}
	}

    private func resultHandler(result:Bool, data:Any?, saveTopShelf:Bool){
        if !result{
            print("Albireo login failed, cookie expired")
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        if let list = data as? [BangumiItemModel]{
            if list.count <= 0 {
                print("bgmList.count <= 0, ignore")
				DispatchQueue.main.async {
					self.isLoading = false
				}
                return
            }else{
                print("loaded \(list.count) items from bgmList")
                self.updateBGMList(list: list)
                
#if os(tvOS)
                if saveTopShelf{
                    let save = SettingsHandler()
                    save.setTopShelf(array: list)
                }
#endif
            }
        }
    }
    
    func isSearchable(selectedFunc:FuncViewModel?) -> Bool{
        if bgmList.count >= 5{
            return true
        }
        if selectedFunc == .search{
            return true
        }
        return false
    }
    
    var bangumiFiltered: [BangumiItemModel] {
//		var searchHistory = settingsHandler.getSearchHistory()
        if self.bgmList.count > 0 && !self.isLoading
        {
            let searchResult = self.bgmList.filter {
                ($0.name ?? "").localizedStandardContains(self.searchText) || (($0.name_cn ?? "").localizedStandardContains(self.searchText))
            }
            print("animeArr:\(self.bgmList.count),filtered:\(searchResult.count)")
//			if searchResult.count > 0{
//				if !searchHistory.contains(self.searchText) {
//					searchHistory.append(self.searchText)
//					settingsHandler.setSearchHistory(history: searchHistory)
//					print("saved:\(searchHistory)")
//				}
//			}
            return self.searchText.isEmpty ? self.bgmList : searchResult
        }else{
            print("self.bgmList.count <= 0")
            return []
        }
    }
    
}
