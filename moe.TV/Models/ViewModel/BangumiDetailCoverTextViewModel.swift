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

	@Published var bgmItem:BangumiItemModel?
	@Published var detailVM:BangumiDetailViewModel?


    func toggleChangeFavStatusAlert() {
        self.presentFavStatusSelecter.toggle()
    }
	func setDetailVM(dVM:BangumiDetailViewModel){
		self.detailVM = dVM
	}



    func changeFavStatus(idstr:String, bgmid:Int?, status:Int) {
        print("changing fav status to \(status)")
        changeAlbireoFavStatus(bangumi_id: idstr, status: status, completion: { isSuccess, result in
            if isSuccess {
                print(result as Any)
				DispatchQueue.main.async {
					self.presentAlbireoFavChangeResultDone.toggle()
				}
            }
        })
        
        if let bgm_id = bgmid{
            setBGMCollectionStatus(subject_id: bgm_id, status: status) { isSuccess, result in
				print(result as Any)
				if isSuccess {
					DispatchQueue.main.async {
						self.presentBGMFavChangeResultDone.toggle()
					}
				}else{
					print("setBGMCollectionStatus retrun false")
				}
            }
		}else{
			print("bgmid not found")
		}
		if let item = bgmItem{
			if let dVM = self.detailVM{
				dVM.getBGMDetail(id: item.id)
			}
		}
    }
}
