//
//  BangumiListViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/09.
//

import Foundation


class BangumiListViewModel: ObservableObject{
    @Published var myBGMList = [MyBangumiItemModel]()
    
    func updateMyBGMList(list:[MyBangumiItemModel]){
        print("setting \(list.count) object")
        DispatchQueue.main.async {
            self.myBGMList = list
        }
    }
    
    func getBGMList() {
        print("init.getBGMList")
        getMyBangumiList { result, data in
            if !result{
                //TODO: login failed, cookie expired
                print("login failed, cookie expired")
                return
            }
            if let bgmList = data as? [MyBangumiItemModel]{
                self.updateMyBGMList(list: bgmList)
#if os(tvOS)
            let save = SaveHandler()
                save.setTopShelf(array: bgmList)
#endif
            }
        }
    }
}
