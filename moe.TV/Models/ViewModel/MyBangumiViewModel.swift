//
//  MyBangumiViewModel.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/07/04.
//

import Foundation

class MyBangumiViewModel: ObservableObject{
    @Published var presentSettingView = false
    @Published var myBGMList = [MyBangumiItemModel]()
    @Published var bgmProfileIcon = ""
    
    func setBGMProfileIcon(url:String){
        self.bgmProfileIcon = url
    }
    func getBGMProfileIcon() -> String{
        print("bgmtv profile url:\(self.bgmProfileIcon)")
        return self.bgmProfileIcon
    }
    
    func setBGMList(list:[MyBangumiItemModel]){
        self.myBGMList = list
    }
    func getBGMList() -> [MyBangumiItemModel]{
        return self.myBGMList
    }
    
    func toggleSettingView(){
        self.presentSettingView.toggle()
    }
}
