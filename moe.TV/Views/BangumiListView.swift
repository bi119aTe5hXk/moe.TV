//
//  BangumiListView.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/10.
//

import SwiftUI

struct BangumiListView: View {
    @Binding var animeArr:[MyBangumiItemModel]
    @State var selectedItem:MyBangumiItemModel?

    var body: some View {
        List{
            ForEach(animeArr) { item in
                NavigationLink(destination: BangumiDetailView(bangumiItem: item),
                               tag: item,
                               selection:$selectedItem){
                    BangumiCellView(bangumiItem: item)
                }
            }

        }.listStyle(.sidebar)
            
            
    }
}

struct BangumiListView_Previews: PreviewProvider {
    static var previews: some View {
        BangumiListView(animeArr: .constant([testBangumiItem1]), selectedItem: testBangumiItem1)
    }
}
