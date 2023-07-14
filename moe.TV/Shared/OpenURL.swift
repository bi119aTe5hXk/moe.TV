//
//  OpenURL.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/02.
//

import Foundation

#if os(iOS)
import UIKit
import SafariServices
func openURLInApp(urlString:String){
    if let url = URL(string: urlString){
        let vc = SFSafariViewController(url: url)
        UIApplication.shared.firstKeyWindow?.rootViewController?.present(vc, animated: true)
    }
}
//TODO: open auth web inside app
func openURL(urlString:String){
    if let url = URL(string: urlString){
        UIApplication.shared.open(url)
    }
}
extension UIApplication {
    var firstKeyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .first?.keyWindow
    }
}
#endif

#if os(macOS)
import Cocoa
func openURLInApp(urlString:String){
    openURL(urlString: urlString)
}
func openURL(urlString:String){
    if let url = URL(string: urlString){
        NSWorkspace.shared.open(url)
    }
}
#endif

