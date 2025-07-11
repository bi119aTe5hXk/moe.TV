//
//  BangumiListView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

struct BangumiListView: View {
	@ObservedObject var listVC = BangumiListViewController()
    @Binding var selectedItem: BangumiItemModel?
    @Binding var selectedFunc: FuncViewModel?

	@State private var oldValue: FuncViewModel?

	private let settingsHandler = SettingsHandler()

    var body: some View {
        if listVC.isLoading{
            ProgressView()
        }
		List(listVC.bangumiFiltered, id: \.self, selection: $selectedItem){ item in
                NavigationLink(value: item) {
                    BangumiCellView(bangumiItem: item)
                }
            }
            .refreshable {
                print("refreshable.getBGMList")
                getBGMList()
            }
            .onAppear(){
#if os(iOS)
				if UIDevice.current.userInterfaceIdiom == .phone && settingsHandler.getLandscapePlayback(){
					OrientationController.shared.unlockOrientation()
					OrientationController.shared.currentOrientation = .portrait
				}
#endif
            }
            .onChange(of: selectedFunc, initial: true) {  newValue in
				if oldValue != newValue {
					print("onChange.getBGMList")
					oldValue = newValue
					getBGMList()
				}
            }

            .modifier(OptionalSearchableViewModifier(
                isSearchable: listVC.isSearchable(selectedFunc: selectedFunc),
                selectedFunc: selectedFunc,
                listVC: listVC,
                searchString: $listVC.searchText))

        
            .alert("Albireo cookies may expired. Logout?",isPresented: $listVC.showLogoutAlert) {
                Button("Yes, logout & exit") {
                    logoutAlbireoServer { result, str in
                        exit(0);
                    }
                    exit(0);
                }
                Button("No, Stay login"){
                    listVC.showLogoutAlert.toggle()
                }
                
            }
           
    }
    
    func getBGMList(){
        listVC.getBGMList(funcType: selectedFunc, searchKeyword: "")
        
    }
}



struct OptionalSearchableViewModifier: ViewModifier{
    let isSearchable: Bool
    let selectedFunc: FuncViewModel?
	let listVC: BangumiListViewController
    @Binding var searchString: String

	private let settingsHandler = SettingsHandler()
	

    func body(content: Content) -> some View {
		var searchHistory = settingsHandler.getSearchHistory()

        switch isSearchable{
        case true:
            if selectedFunc == .search{
				//for search via API
                content
                    .searchable(text: $searchString, prompt: "Search")
                    .onSubmit(of: .search) {
						if searchString.lengthOfBytes(using: .utf8) > 0{
								print(searchString)
                                listVC.getBGMList(funcType: selectedFunc, searchKeyword: searchString)
                            }else{
                                listVC.bgmList = []
                            }
                        }

            }else{
				//for filtering items
                content
                    .searchable(text: $searchString, prompt: "Filtering...")
					.searchSuggestions {
						if searchString.isEmpty && searchHistory.count > 0{
							Section("History") {
								ForEach(searchHistory, id: \.self) { history in
									Label(history, systemImage: "clock.arrow.circlepath")
										.searchCompletion(history)
										.swipeActions(edge: .trailing, allowsFullSwipe: true) {
											Button(role: .destructive) {
												searchHistory.removeAll { $0 == history }
												settingsHandler.setSearchHistory(history: searchHistory)
											} label: {
												Text("Delete")
											}
										}
								}
							}
						}
					}

					.onSubmit(of: .search){
						print("searchString:\(searchString)")
						if searchString.lengthOfBytes(using: .utf8) > 0{
							if !searchHistory.contains(searchString) {
								searchHistory.append(searchString)
								settingsHandler.setSearchHistory(history: searchHistory)
								print("saved:\(searchHistory)")
							}
						}
					}
            }
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
