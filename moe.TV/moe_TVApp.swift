//
//  moe_TVApp.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/09.
//

import SwiftUI

@main
struct moe_TVApp: App {
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: LoginViewModel())
        }
    }
}
