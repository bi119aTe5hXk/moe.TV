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
        HStack(spacing: 6) {
            Circle()
                .fill(status.map(statusColor) ?? .secondary)
                .frame(width: 7, height: 7)
            if let status {
                Text(statusText(status: status))
                    .foregroundStyle(statusColor(status: status))
            } else {
                Text("No Record")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline.weight(.semibold))
        .lineLimit(1)
    }
    
    private func statusText(status:Int) -> LocalizedStringKey {
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
    private func statusColor(status:Int) -> Color {
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

//#Preview {
//    BGMStatusTextView(status: .constant(1))
//}
