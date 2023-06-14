//
//  BangumiStatusTextView.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/10.
//

import SwiftUI

struct BangumiCellStatusTextView: View {
    @State var bangumiStatus:Int
    var body: some View {
        switch bangumiStatus{
            case 0:
                Text("Pending")
                .foregroundColor(.blue)
                .padding(5)
                .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.blue, lineWidth: 2)
                        )
            case 1:
                Text("OnAir")
                .foregroundColor(.green)
                .padding(5)
                .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.green, lineWidth: 2)
                        )
            case 2:
                Text("Finished")
                .foregroundColor(.gray)
                .padding(5)
                .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.gray, lineWidth: 2)
                        )
            default:
                Text("UNKNOWN")
                .foregroundColor(.red)
                .padding(5)
                .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.red, lineWidth: 2)
                        )
        }
    }
}

struct BangumiCellStatusTextView_Previews: PreviewProvider {
    static var previews: some View {
        BangumiCellStatusTextView(bangumiStatus: 0)
    }
}
