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
            
            //TODO: URL scheme handler
                .onOpenURL { url in
                        print(url.absoluteString)
                }
        }
        
#if !os(tvOS)
        .handlesExternalEvents(matching: [])
#endif
    }
}
#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        print("Unhandled: \(urls)")
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Restore first minimized window if app became active and no one window
        // is visible
        if NSApp.windows.compactMap({ $0.isVisible ? Optional(true) : nil }).isEmpty {
             NSApp.windows.first?.makeKeyAndOrderFront(self)
        }
    }
}
#endif

#if os(iOS)
//extension AppDelegate {
//
//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
//
//        print(url.absolueString)
//        return true
//    }
//}

#endif
