//
//  OfflineVideoManager.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/07.
//

import Foundation
struct OfflineVideoItem: Codable{
    let epID:String?
    var bgm_eps_id:Int?
    var filename:String
    var position:Double
    var isFinished:Bool
}
class OfflinePlaybackManager: ObservableObject {
    // MARK: - Playback manager
//    func isPlayBackStatsExisit(filename:String) -> Bool{
//        if let list = getSaveStatusList(){
//            if list.contains(where: {$0.filename == filename}){
//                return true
//            }
//        }
//        return false
//    }
    
    func getPlayBackStatus(filename:String) -> OfflineVideoItem?{
        if let list = getSaveStatusList(){
            print(list)
            if let item = list.first(where: {$0.filename == filename}) {
                return item
            }
        }
        return nil
    }
    
    func setPlayBackStatus(item:OfflineVideoItem){
        if let oldItem = getPlayBackStatus(filename: item.filename){
            print("found oldItem:\(oldItem)")
            deletePlayBackStatus(filename: oldItem.filename)
        }
        addPlayBackStatus(item: item)
    }
    func addPlayBackStatus(item:OfflineVideoItem){
        print("add:\(item)")
        if var list = getSaveStatusList(){
            list.append(item)
            self.setSaveStatusList(array: list)
        }else{
            self.setSaveStatusList(array: [item])
        }
    }
    
    func deletePlayBackStatus(filename:String){
        if var list = getSaveStatusList(){
            list.removeAll(where: { $0.filename == filename })
            self.setSaveStatusList(array: list)
        }
    }
    
    
    // MARK: - UD Handler
    private let saveHandler = SaveHandler()
    private let kOfflinePlaybackStatus = "offlinePlaybackStatus"
    
    private func getSaveStatusList() -> [OfflineVideoItem]?{
        let arr = saveHandler.readArrayFromPList(key: kOfflinePlaybackStatus)
        var decodeArr = [OfflineVideoItem]()
        arr?.forEach({ item in
            if let data = item as? Data,
               let decodeData = try? PropertyListDecoder().decode(OfflineVideoItem.self, from: data) {
                decodeArr.append(decodeData)
                    }
        })
        print("read(\(decodeArr.count))items:\(decodeArr)")
        if decodeArr.isEmpty{
            return nil
        }
        return decodeArr
    }
    
    private func setSaveStatusList(array:[OfflineVideoItem]){
        print(array)
        
        if array.isEmpty{
            return
        }
        var encodeArr = [Any]()
        array.forEach { item in
            if let encoded = try? PropertyListEncoder().encode(item) {
                encodeArr.append(encoded)
            }
        }
        print("saved(\(encodeArr.count))items:\(encodeArr)")
        saveHandler.saveToPList(key: kOfflinePlaybackStatus, data: encodeArr)
        
    }
}
