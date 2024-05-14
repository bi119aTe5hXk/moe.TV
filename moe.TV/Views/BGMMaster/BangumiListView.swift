//
//  BangumiListView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

struct BangumiListView: View {
    @ObservedObject var listVM = BangumiListViewModel()
    @Binding var selectedItem: MyBangumiItemModel?
    
    var body: some View {
//        if listVM.myBGMList.count <= 0{
//            VStack{
//                ProgressView()
//                Text("Loading...")
//            }
//            .onAppear(){
//                print("onAppear.getBGMList")
//                listVM.getBGMList()
//            }
//        }else{
            List(listVM.bangumiFiltered, selection: $selectedItem){ item in
                NavigationLink(value: item) {
                    BangumiCellView(bangumiItem: item)
                }
            }
            .refreshable {
                print("refreshable.getBGMList")
                listVM.getBGMList()
            }
            .onAppear(){
                if listVM.myBGMList.count <= 0{
                    print("onAppear.getBGMList")
                    listVM.getBGMList()
                }
            }
        
            //.searchable(text: $listVM.searchText)
            .modifier(OptionalSearchableViewModifier(isSearchable: listVM.myBGMList.count >= 2, searchString: $listVM.searchText))
        
//        }
           
    }
    
    
}

struct OptionalSearchableViewModifier: ViewModifier{
    let isSearchable: Bool
    @Binding var searchString: String
    
    func body(content: Content) -> some View {
        switch isSearchable{
        case true:
            content
                .searchable(text: $searchString, prompt: "Search")
        case false:
            content
        }
    }
}

//struct BangumiListView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiListView(animeArr: .constant([testBangumiItem1]), selectedItem: testBangumiItem1)
//    }
//}
