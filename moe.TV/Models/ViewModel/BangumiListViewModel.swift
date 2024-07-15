//
//  BangumiListViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/09.
//

import Foundation


class BangumiListViewModel: ObservableObject{
    @Published var bgmList = [BangumiItemModel]()
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var showLogoutAlert = false
    
    private func updateBGMList(list:[BangumiItemModel]){
        print("setting \(list.count) objects")
        
        DispatchQueue.main.async {
            self.isLoading = false
            self.bgmList = list
        }
    }
    
    
    func getBGMList(funcType:FuncViewModel?, searchKeyword:String){
        if let type = funcType{
            isAlbireoLoginValid { result in
                if result{
                    self.isLoading = true
                    
                    switch type {
                    case .mybangumi:
                        print("BangumiListViewModel.getMyBGMList")
                        getMyBangumiList { result, data in
                            self.resultHandler(result: result, data: data, saveTopShelf: true)
                        }
                        return
                    case .onair:
                        print("BangumiListViewModel.getOnAirBGMList")
                        getOnAirList { result, data in
                            self.resultHandler(result: result, data: data, saveTopShelf: false)
                        }
                        return
                    case .search:
                        //TODO: Search
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.bgmList = []
                        }
                        return
                    case .allbangumi:
                        getAllBangumiList(page: 1, name: "") { result, data in
                            self.resultHandler(result: result, data: data, saveTopShelf: false)
                        }
                        return
                    }
                }else{
                    print("Albireo login info error. Cookie expired?")
                    self.showLogoutAlert.toggle()
                }
            }
            
        }
    }
    
    private func resultHandler(result:Bool, data:Any?, saveTopShelf:Bool){
        if !result{
            print("login failed, cookie expired")
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        if let list = data as? [BangumiItemModel]{
            if list.count <= 0 {
                print("bgmList.count <= 0, ignore")
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
        if bgmList.count >= 2{
            return true
        }
        if selectedFunc == .search{
            return true
        }
        return false
    }
    
    //TODO: search all bangumi via albireo API
    var bangumiFiltered: [BangumiItemModel] {
        
        if self.bgmList.count > 0
            && !self.isLoading
        {
            let searchResult = self.bgmList.filter {
                ($0.name ?? "").localizedStandardContains(self.searchText) || (($0.name_cn ?? "").localizedStandardContains(self.searchText))
            }
            print("animeArr:\(self.bgmList.count),filtered:\(searchResult.count)")
            return self.searchText.isEmpty ? self.bgmList : searchResult
        }else{
            print("self.bgmList.count <= 0")
            return []
        }
    }
    
}
