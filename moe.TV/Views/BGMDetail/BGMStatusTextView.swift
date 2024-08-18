//
//  BGMStatusTextView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2024/08/18.
//

import SwiftUI

struct BGMStatusTextView: View {
    @Binding var status:Int?
    
    
    var body: some View {
//        Text("\(status)")

        if let s = status{
            Text(statusText(status: s))
                .padding(8)
                .foregroundStyle(statusColor(status: s))
                .bold()
#if !os(tvOS)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(statusColor(status: s), lineWidth:1))
#endif
                
        }else{
            Text("No Record")
                .padding(8)
                .foregroundStyle(Color(UIColor.label))
                .bold()
#if !os(tvOS)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(UIColor.label), lineWidth:1))
#endif
        }

    }
    
    func statusText(status:Int) -> String {
        switch status {
        case 1:
            return "Wish"
        case 2:
            return "Watched"
        case 3:
            return "Watching"
        case 4:
            return "Pause"
        case 5:
            return "Abandoned"
        default:
            return "UNKNOW_STATUS"
        }
    }
    func statusColor(status:Int) -> Color {
        switch status {
        case 1:
            return .pink
        case 2:
            return .green
        case 3:
            return .blue
        case 4:
            return .gray
        case 5:
            return .gray
        default:
            return .red
        }
    }
}

#Preview {
    BGMStatusTextView(status: .constant(1))
}
