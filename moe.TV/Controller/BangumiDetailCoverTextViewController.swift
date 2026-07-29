//
//  BangumiDetailCoverTextViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2024/08/18.
//

import Foundation
class BangumiDetailCoverTextViewController: ObservableObject {
    @Published var presentFavStatusSelecter = false
    @Published var presentAlbireoFavChangeResultDone = false
	@Published var presentBGMFavChangeResultDone = false
    
    @Published var presentAlbreoFavStatusNilAlert = false
    @Published var presentBGMFavStatusNilAlert = false
    @Published var presentFavStatusConflictAlert = false
    
	@Published var bgmItem:BangumiItemModel?
	@Published var detailVC:BangumiDetailViewController?
    
    var albireoFavStatus:Int?
    var bgmFavStatus:Int?
    
    private var lastHandledPair: (Int?, Int?)?
    
    var settingsHandler = SettingsHandler()

    func toggleChangeFavStatusAlert() {
        self.presentFavStatusSelecter.toggle()
    }
	func setDetailVC(dVC:BangumiDetailViewController){
		self.detailVC = dVC
	}

    func checkFavConflict(a: Int?, b: Int?) {
        guard settingsHandler.getCheckFavStatusConflict(), isBGMTVlogined() else { return }

        let albireo: Int? = (a == 0 ? nil : a)
        let bgm: Int?     = (b == 0 ? nil : b)

        if let last = lastHandledPair, last.0 == albireo, last.1 == bgm { return }
        lastHandledPair = (albireo, bgm)

        resetAlertFlags()

        switch (albireo, bgm) {
        case (nil, nil):
            return

        case (nil, .some):
            presentAlbreoFavStatusNilAlert = true
            return

        case (.some, nil):
            presentBGMFavStatusNilAlert = true
            return

        case let (.some(av), .some(bv)):
            guard av != bv else { return }
            albireoFavStatus = av
            bgmFavStatus = bv
            presentFavStatusConflictAlert = true
            return
        }
    }
    private func resetAlertFlags() {
        presentAlbreoFavStatusNilAlert = false
        presentBGMFavStatusNilAlert = false
        presentFavStatusConflictAlert = false
    }
    
    func setAlbreoFavStatus(idstr:String, status:Int){
        print("changing albireo fav status to \(status)")
        changeAlbireoFavStatus(bangumi_id: idstr, status: status, completion: { isSuccess, result in
            if isSuccess {
                print(result as Any)
                DispatchQueue.main.async {
                    self.detailVC?.albireo_favorite_status = status
                    self.presentAlbireoFavChangeResultDone.toggle()
                }
            }
        })
    }
    func setBGMFavStatus(bgmid:Int?, status:Int){
        print("changing bgm.tv fav status to \(status)")
        if let bgm_id = bgmid{
            setBGMCollectionStatus(subject_id: bgm_id, status: status) { isSuccess, result in
                print(result as Any)
                if isSuccess {
                    DispatchQueue.main.async {
                        self.detailVC?.bgmtv_favorite_status = status
                        self.presentBGMFavChangeResultDone.toggle()
                    }
                }else{
                    print("setBGMCollectionStatus retrun false")
                }
            }
        }else{
            print("bgmid not found")
        }
        //        if let item = bgmItem{
        //            if let dVM = self.detailVC{
        //                dVM.getBGMDetail(id: item.id)
        //            }
        //        }
    }

    func changeFavStatusAll(idstr:String, bgmid:Int?, status:Int) {
        setAlbreoFavStatus(idstr: idstr, status: status)
        setBGMFavStatus(bgmid: bgmid, status: status)
        
    }
}
