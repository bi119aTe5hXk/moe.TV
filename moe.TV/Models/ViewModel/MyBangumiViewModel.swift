//
//  MyBangumiViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/04.
//

import Foundation

class MyBangumiViewModel: ObservableObject{
    @Published var presentSettingView = false
    
    func toggleSettingView(){
        self.presentSettingView.toggle()
    }
    
    
}
