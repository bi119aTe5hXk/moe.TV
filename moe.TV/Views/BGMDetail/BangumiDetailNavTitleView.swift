//
//  BangumiDetailNavBarView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/19.
//

import SwiftUI

struct BangumiDetailNavTitleView: View {
    @Binding var item:BangumiDetailModel?
    
    var body: some View {
        
        VStack {
            if let i = item{
                Text(i.name ?? "")
                    .font(.headline.bold())
                Text(i.name_cn ?? "")
                    .font(.subheadline)
            }
            
        }
    }
}

//struct BangumiDetailNavBarView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiDetailNavBarView()
//    }
//}
