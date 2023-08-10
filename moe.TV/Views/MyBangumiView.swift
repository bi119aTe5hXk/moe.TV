//
//  MyBangumiView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

struct MyBangumiView: View {
    @ObservedObject var myBangumiVM: MyBangumiViewModel
    @State var selectedItem: MyBangumiItemModel?
    
    var body: some View {
        NavigationSplitView {
            BangumiListView(listVM: BangumiListViewModel(),selectedItem: $selectedItem)
                
                .navigationTitle("My Bangumi")
                .toolbar(content: {
#if os(macOS)
                    Spacer()
#endif
                    Button(action: {
                        myBangumiVM.toggleSettingView()
                    }, label: {
                        //TODO: logo not show
                        if !myBangumiVM.bgmProfileIcon.isEmpty{
                            AsyncImage(url: URL(string: myBangumiVM.bgmProfileIcon)) { image in
                                image.resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                            }
                        }else{
                            Image(systemName: "gear")
                        }
                    })
                })
            
        } detail: {
            BangumiDetailView(selectedItem: $selectedItem)
        }
        .onAppear(){
            if isBGMTVlogined() && myBangumiVM.bgmProfileIcon.isEmpty{
                myBangumiVM.fetchBGMProfileIcon()
            }
        }
        
        .sheet(isPresented: $myBangumiVM.presentSettingView, content: {
            HStack{
#if !os(tvOS)
                Button(action: {
                    myBangumiVM.toggleSettingView()
                }, label: {
                    Text("Close")
                }).padding(20)
                Spacer()
#endif
            }
            SettingsView(loginVM: LoginViewModel(),
                         myBangumiVM: myBangumiVM,
                         settingsVM: SettingsViewModel())
#if os(macOS)
        .frame(width: NSApp.keyWindow?.contentView?.bounds.width ?? 500, height: NSApp.keyWindow?.contentView?.bounds.height ?? 500)
#endif
            Spacer()
        })
    }
}

//struct MyBangumiView_Previews: PreviewProvider {
//    static var previews: some View {
//        MyBangumiView(myBGMList: <#T##[MyBangumiItemModel]#>, myBangumiVM: <#T##MyBangumiViewModel#>)
//    }
//}
