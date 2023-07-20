//
//  BangumiListView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

struct BangumiListView: View {
    @Binding var animeArr:[MyBangumiItemModel]
    @State var selectedItem:MyBangumiItemModel?
    @State private var searchText = ""
    
    var body: some View {
        List{
            ForEach(bangumiFiltered, id: \.self) { item in
                NavigationLink(destination: BangumiDetailView(bgmID: .constant(item.id)),
                               tag: item,
                               selection:$selectedItem){
                    BangumiCellView(bangumiItem: item)
                }
            }
            
        }
            //        .listStyle(.sidebar)
        .searchable(text: $searchText)
           
    }
    
    //TODO: search all bangumi via albireo API
    private var bangumiFiltered: [MyBangumiItemModel] {
        let searchResult = animeArr.filter {
            ($0.name ?? "").localizedStandardContains(searchText) || (($0.name_cn ?? "").localizedStandardContains(searchText))
            
        }
            return searchText.isEmpty ? animeArr : searchResult
        }
}

//struct BangumiListView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiListView(animeArr: .constant([testBangumiItem1]), selectedItem: testBangumiItem1)
//    }
//}
