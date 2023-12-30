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
        //TODO: update view after first login
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
            .searchable(text: $listVM.searchText)
//        }
           
    }
    
    
}

//struct BangumiListView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiListView(animeArr: .constant([testBangumiItem1]), selectedItem: testBangumiItem1)
//    }
//}
