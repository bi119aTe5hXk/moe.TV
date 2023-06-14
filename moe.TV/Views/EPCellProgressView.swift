//
//  EPCellProgressView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/14.
//

import SwiftUI

struct EPCellProgressView: View {
    @Binding var progress: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 10.0)
                .opacity(0.3)
                .foregroundColor(.orange)

            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                .foregroundColor(.orange)
                .rotationEffect(Angle(degrees: 270.0))

            Text(String(format: "%.0f%%", min(progress, 1.0) * 100.0))
                .font(.system(size: 10))
                .bold()
        }
    }
}

struct ContentView: View {
    @State var progressValue: CGFloat = 0.3

    var body: some View {
        VStack {
            EPCellProgressView(progress: $progressValue)
                //.frame(width: 100.0, height: 100.0)
                .font(.system(size: 10))
                .padding(32.0)
            Spacer()
        }
    }
}

struct EPCellProgressView_Previews: PreviewProvider {
    static var previews: some View {
        EPCellProgressView(progress: .constant(0.9999707400885012))
    }
}
