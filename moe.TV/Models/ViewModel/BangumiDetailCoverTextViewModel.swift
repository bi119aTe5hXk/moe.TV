//
//  BangumiDetailCoverTextViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2024/08/18.
//

import Foundation
class BangumiDetailCoverTextViewModel: ObservableObject {
    @Published var presentFavStatusSelecter = false
    @Published var presentFavChangeResultDone = false
    
    func toggleChangeFavStatusAlert() {
        self.presentFavStatusSelecter.toggle()
    }
    func changeFavStatus(bgmid:String, status:Int) {
        print("changing fav status to \(status)")
        changeAlbireoFavStatus(bangumi_id: bgmid, status: status, completion: { isSuccess, result in
            if isSuccess {
                print(result as Any)
                self.presentFavChangeResultDone.toggle()
            }
        })
    }
}
