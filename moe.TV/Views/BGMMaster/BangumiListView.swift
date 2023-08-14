//
//  BangumiListView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

struct BangumiListView: View {
    @State var listVM = BangumiListViewModel()
    @Binding var selectedItem: MyBangumiItemModel?
    @State private var searchText = ""
    
    var body: some View {
        //TODO: update view after first login
        if listVM.isLoading{
            VStack{
                ProgressView()
                Text("Loading...")
            }
        }else{
            List(bangumiFiltered, selection: $selectedItem){ item in
                NavigationLink(value: item) {
                    BangumiCellView(bangumiItem: item)
                }
            }
            .refreshable {
                print("pulled")
                listVM.getBGMList()
            }
            .onChange(of: listVM.myBGMList, perform: { newValue in
                listVM.updateMyBGMList(list: newValue)
            })
            .onAppear(){
                if listVM.myBGMList.count <= 0{
                    print("BangumiListView.onAppear.getBGMList")
                    listVM.getBGMList()
                }
            }
            //        .listStyle(.sidebar)
            .searchable(text: $searchText)
        }
           
    }
    
    //TODO: search all bangumi via albireo API
    private var bangumiFiltered: [MyBangumiItemModel] {
        let searchResult = listVM.myBGMList.filter {
            ($0.name ?? "").localizedStandardContains(searchText) || (($0.name_cn ?? "").localizedStandardContains(searchText))
        }
        //print("animeArr:\(myBangumiVM.myBGMList.count),filtered:\(searchResult.count)")
        return searchText.isEmpty ? listVM.myBGMList : searchResult
    }
}

//struct BangumiListView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiListView(animeArr: .constant([testBangumiItem1]), selectedItem: testBangumiItem1)
//    }
//}
