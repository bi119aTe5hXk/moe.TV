//
//  BangumiDetailCoverTextViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2024/08/18.
//

import Foundation
class BangumiDetailCoverTextViewModel: ObservableObject {
    @Published var presentFavStatusSelecter = false
    @Published var presentAlbireoFavChangeResultDone = false
	@Published var presentBGMFavChangeResultDone = false

    func toggleChangeFavStatusAlert() {
        self.presentFavStatusSelecter.toggle()
    }
    func changeFavStatus(idstr:String, bgmid:Int?, status:Int) {
        print("changing fav status to \(status)")
        changeAlbireoFavStatus(bangumi_id: idstr, status: status, completion: { isSuccess, result in
            if isSuccess {
                print(result as Any)
                self.presentAlbireoFavChangeResultDone.toggle()
            }
        })
        
        if let bgmid = bgmid{
            setBGMCollectionStatus(subject_id: bgmid, status: status) { isSuccess, result in
                if isSuccess {
                    print(result as Any)
                    self.presentBGMFavChangeResultDone.toggle()
                }
            }
        }
        
        
    }
}
