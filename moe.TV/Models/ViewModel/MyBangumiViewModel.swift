//
//  MyBangumiViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/04.
//

import Foundation

class MyBangumiViewModel: ObservableObject{
    @Published var presentSettingView = false
    @Published var myBGMList = [MyBangumiItemModel]()
    @Published var bgmProfileIcon = ""
    
    func setBGMProfileIcon(url:String){
        DispatchQueue.main.async {
            self.bgmProfileIcon = url
        }
    }
    func getBGMProfileIcon() -> String{
//        print("bgmtv profile url:\(self.bgmProfileIcon)")
        return self.bgmProfileIcon
    }
    
    func setBGMList(list:[MyBangumiItemModel]){
        DispatchQueue.main.async {
            self.myBGMList = list
        }
    }
    func getBGMList() -> [MyBangumiItemModel]{
        return self.myBGMList
    }
    
    func toggleSettingView(){
        self.presentSettingView.toggle()
    }
}
