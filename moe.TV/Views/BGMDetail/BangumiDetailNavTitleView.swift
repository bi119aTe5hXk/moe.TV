//
//  BangumiDetailNavBarView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/19.
//

import SwiftUI

struct BangumiDetailNavTitleView: View {
    @State var item:BangumiDetailModel
    
    var body: some View {
        
        VStack {
            Text(item.name ?? "")
                .font(.headline.bold())
            Text(item.name_cn ?? "")
                .font(.subheadline)
        }
        
    }
}

//struct BangumiDetailNavBarView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiDetailNavBarView()
//    }
//}
