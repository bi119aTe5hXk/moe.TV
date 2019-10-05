//
//  Extensions.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2019/09/01.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import Foundation
import UIKit
extension UIImageView {
func roundedImage(corners: UIRectCorner, radius: CGFloat)  {
        let rect = CGRect(origin:CGPoint(x: 0, y: 0), size: self.frame.size)
        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 1)
        UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
            ).addClip()
        self.draw(rect)
        self.image = UIGraphicsGetImageFromCurrentImageContext()!

        // Shadows - Change shadowOpacity to value > 0 to enable the shadows
        self.layer.shadowOpacity = 0
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 10, height: 15)
        self.layer.shadowRadius = 3

        // This propagate the transparency to the the overlay layers,
        // like the one for the glowing effect.
    if #available(tvOS 11.0, *) {
        self.masksFocusEffectToContents = true
    } else {
        // Fallback on earlier versions
    }
    }
}
