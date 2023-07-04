//
//  OpenURL.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/07/02.
//

import Foundation
#if os(iOS)
import UIKit
func openURL(urlString:String){
    if let url = URL(string: urlString){
        UIApplication.shared.open(url)
    }
}
#endif

#if os(macOS)
import Cocoa
func openURL(urlString:String){
    if let url = URL(string: urlString){
        NSWorkspace.shared.open(url)
    }
}
#endif

