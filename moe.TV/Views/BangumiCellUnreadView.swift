//
//  BangumiUnreadView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/13.
//

import SwiftUI

struct BangumiCellUnreadView: View {
    @State var unreadCount:Int
    var body: some View {
        if unreadCount >= 1{
            Text(String(unreadCount))
                .padding(5)
                .foregroundColor(.white)
                .background(Color.orange.cornerRadius(5))
        }
    }
}

struct BangumiCellUnreadView_Previews: PreviewProvider {
    static var previews: some View {
        BangumiCellUnreadView(unreadCount: 5)
    }
}
