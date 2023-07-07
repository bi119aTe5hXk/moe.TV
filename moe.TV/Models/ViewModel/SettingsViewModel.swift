//
//  SettingsViewModel.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/07/07.
//

import Foundation

class SettingsViewModel: ObservableObject{
    @Published var presentLogoutAlbireoAlert = false
    @Published var presentLogoutBGMTVAlert = false
    
    func showLogoutAlbireoAlert(){
        self.presentLogoutAlbireoAlert = true
    }
    func showLogoutBGMTVAlert(){
        self.presentLogoutBGMTVAlert = true
    }
}
