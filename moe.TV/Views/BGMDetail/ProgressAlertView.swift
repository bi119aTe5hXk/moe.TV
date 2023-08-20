//
//  ProgressAlertView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/20.
//

import SwiftUI

public struct ProgressAlertView: View {
    @Binding var progress:Double
    
    public var body: some View {
        VStack {
            ProgressView(value: progress) {
                Text("Downloading...\(Int(round(progress * 100)))%")
            }
            .progressViewStyle(.circular)
            .scaleEffect(1.5)
        }
    }
}

public struct ProgressAlertView_Previews: PreviewProvider {
    static public var previews: some View {
        ProgressAlertView(progress: .constant(0.7))
    }
}
