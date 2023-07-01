//
//  OpenURL.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/07/02.
//

import Foundation
#if os(iOS)
import UIKit
#endif

func openURL(urlString:String){
    if let url = URL(string: urlString){
#if os(macOS)
        NSWorkspace.shared.open(url)
#else
        UIApplication.shared.open(url)
#endif
    }
}
