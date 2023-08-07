//
//  OfflineVideoManager.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/07.
//

import Foundation
class OfflinePlaybackManager: ObservableObject {
    // MARK: - Playback manager
    
//    func isPlayBackStatsExisit() -> Bool{
//        
//    }
    
    func readPlayBackStatus(){
        
    }
    
    func savePlayBackStatus(epID:String,
                            bgmEPID:Int,
                            filename:String,
                            position:String,
                            isDone:Bool){
        
    }
    
    
    // MARK: - Plist File Handler
    private func getSaveFilePath() -> URL?{
        do {
            let documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return documentsDirectory.appendingPathComponent("videos.plist")
                
        }catch{
            print(error)
            return nil
        }
    }
    private func readSaveFile() -> [String:Any]?{
        if let path = getSaveFilePath(){
            guard let plistData = FileManager.default.contents(atPath: path.path) else { return nil }
            guard let plist = try? PropertyListSerialization.propertyList(from: plistData, options: .mutableContainers, format:nil) as? [String:Any] else { return nil }
            print(plist)
            return plist
        }else{
            print("failed to read videos.plist")
            return nil
        }
    }
    private func writeSaveFile(dict:[String:Any]){
        print(dict)
        if let path = getSaveFilePath(){
            do{
                let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
                try data.write(to: path)
            }catch{
                print(error)
            }
        }
    }
}
