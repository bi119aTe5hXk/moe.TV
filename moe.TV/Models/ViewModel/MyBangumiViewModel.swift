//
//  MyBangumiViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/04.
//

import Foundation

class MyBangumiViewModel: ObservableObject{
    @Published var presentSettingView = false
    @Published var bgmProfileIcon = ""
    
    func setBGMProfileIcon(url:String){
        DispatchQueue.main.async {
            self.bgmProfileIcon = url
        }
    }
    
    func toggleSettingView(){
        self.presentSettingView.toggle()
    }
    
    func fetchBGMProfileIcon(){
        if isBGMTVlogined(){
            getBGMTVUserInfo(completion: { result, data in
                if result{
                    if let d = data as? BGMTVUserInfoModel{
                        let url = d.avatar?.large ?? ""
                        self.setBGMProfileIcon(url: url)
                    }else{
                        print("bgm.tv user info invalid, should delete bgm.tv user info")
                        logoutBGMTV()
                    }
                }else{
                    print("bgm.tv oauth info invalid")
                    //logoutBGMTV()
                }
            })
        }
    }
}
