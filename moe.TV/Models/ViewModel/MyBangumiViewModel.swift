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
