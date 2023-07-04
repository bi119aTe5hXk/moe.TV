//
//  EPCellProgressView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/14.
//

import SwiftUI

struct EPCellProgressView: View {
    @Binding var progress: CGFloat
    @Binding var color:Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 5.0)
                .opacity(0.3)
                .foregroundColor(color)

            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270.0))

            Text(String(format: "%.0f%%", min(progress, 1.0) * 100.0))
                .font(.system(size: 10))
                .bold()
        }
    }
}

//struct EPCellProgressView_Previews: PreviewProvider {
//    static var previews: some View {
//        EPCellProgressView(progress: .constant(0.9999707400885012),color: .constant(.orange))
//    }
//}
