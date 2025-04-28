//
//  EPCellProgressView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/14.
//

import SwiftUI

struct EPCellProgressView: View {
	@Binding var bgmWatchStatus: Int?
    @Binding var progress: CGFloat
    @Binding var color:Color

    var body: some View {
		//TODO: Add watched status
        ZStack {
            Circle()
                .stroke(lineWidth: 8.0)
                .opacity(0.3)
                .foregroundColor(color)

            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270.0))

			VStack {
				Text(String(format: "%.0f%%", min(progress, 1.0) * 100.0))
					.font(.system(size: 15))
					.bold()

				if bgmWatchStatus == 2 {
					Image(systemName: "checkmark")
						.foregroundColor(.green)
						.font(.system(size: 15))
				}
			}

        }
		.onAppear() {
			print("EPCellProgressView: progress: \(progress)")
		}
    }
}

//struct EPCellProgressView_Previews: PreviewProvider {
//    static var previews: some View {
//        EPCellProgressView(progress: .constant(0.9999707400885012),color: .constant(.orange))
//    }
//}
