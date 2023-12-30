//
//  BangumiListViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/09.
//

import Foundation


class BangumiListViewModel: ObservableObject{
    @Published var myBGMList = [MyBangumiItemModel]()
    @Published var isLoading = false
    @Published var searchText = ""
    
    func updateMyBGMList(list:[MyBangumiItemModel]){
        print("setting \(list.count) objects")
        
        DispatchQueue.main.async {
            self.isLoading = false
            self.myBGMList = list
        }
    }
    
    func getBGMList() {
        self.isLoading = true
        print("BangumiListViewModel.getBGMList")
        
        getMyBangumiList { result, data in
//            self.isLoading = false
            if !result{
                //TODO: login failed, cookie expired
                print("login failed, cookie expired")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            if let bgmList = data as? [MyBangumiItemModel]{
                if bgmList.count <= 0 {
                    print("bgmList.count <= 0, ignore")
                    return
                }else{
                    print("loaded \(bgmList.count) items from bgmList")
                    self.updateMyBGMList(list: bgmList)
#if os(tvOS)
                    let save = SettingsHandler()
                    save.setTopShelf(array: bgmList)
#endif
                }
            }
        }
    }
    
    //TODO: search all bangumi via albireo API
    var bangumiFiltered: [MyBangumiItemModel] {
        if self.myBGMList.count > 0 && !self.isLoading{
            let searchResult = self.myBGMList.filter {
                ($0.name ?? "").localizedStandardContains(self.searchText) || (($0.name_cn ?? "").localizedStandardContains(self.searchText))
            }
            print("animeArr:\(self.myBGMList.count),filtered:\(searchResult.count)")
            return self.searchText.isEmpty ? self.myBGMList : searchResult
        }else{
            print("self.myBGMList.count <= 0")
            return []
        }
    }
    
    
}
