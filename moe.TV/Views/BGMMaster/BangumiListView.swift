//
//  BangumiListView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

struct BangumiListView: View {
    @ObservedObject var listVM = BangumiListViewModel()
    @Binding var selectedItem: BangumiItemModel?
    @Binding var selectedFunc: FuncViewModel?
    
    var body: some View {
        if listVM.isLoading{
            ProgressView()
        }
            List(listVM.bangumiFiltered, selection: $selectedItem){ item in
                NavigationLink(value: item) {
                    BangumiCellView(bangumiItem: item)
                }
            }
            .refreshable {
                print("refreshable.getBGMList")
                getBGMList()
            }
//            .onAppear(){
//                if listVM.bgmList.count <= 0{
//                    print("onAppear.getBGMList")
//                    getBGMList()
//                }
//            }
            .onChange(of: selectedFunc, initial: true) {  newValue in
                print("onChange.getBGMList")
                getBGMList()
            }
        
            //.searchable(text: $listVM.searchText)
            .modifier(OptionalSearchableViewModifier(isSearchable: listVM.isSearchable(selectedFunc: selectedFunc), searchString: $listVM.searchText))
        
//        }
        
            .alert("Albireo cookies may expired. Logout?",isPresented: $listVM.showLogoutAlert) {
                Button("Yes, logout & exit") {
                    logoutAlbireoServer { result, str in
                        exit(0);
                    }
                    exit(0);
                }
                Button("No, Stay login"){
                    listVM.showLogoutAlert.toggle()
                }
                
            }
            //.navigationTitle(" \( selectedFunc?.localizedName ) ")
           
    }
    
    func getBGMList(){
        listVM.getBGMList(funcType: selectedFunc, searchKeyword: "")
        
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
