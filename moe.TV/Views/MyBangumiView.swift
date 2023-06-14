//
//  MyBangumiView.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/10.
//

import SwiftUI

struct MyBangumiView: View {
    @State var myBGMList = [MyBangumiItemModel]()
    @State private var selectedItem:MyBangumiItemModel? = nil
    
    @State var presentSettingView:Bool = false
    
    var body: some View {
        NavigationView {
            let _ = {
                getBGMList()
            }()
            BangumiListView(animeArr: $myBGMList)
                .refreshable {
                    getBGMList()
                }
                .navigationTitle("My Bangumi")
                .toolbar(content: {
                    Button(action: {
                        self.presentSettingView.toggle()
                    }, label: {
                        Image(systemName: "gear")
                            
                    })
                })
            BangumiDetailView(bangumiItem: nil)
        }
        .sheet(isPresented: $presentSettingView, content: {
            Spacer()
            SettingsView()
            Button(action: {
                self.presentSettingView.toggle()
            }, label: {
                Text("Cancel")
            }).padding(10)
            Spacer()
        })
    }
    func getBGMList() {
        getMyBangumiList { result, data in
            if !result{
                return
            }
            if let bgmList = data as? [MyBangumiItemModel]{
                self.myBGMList = bgmList
            }
        }
    }
}


struct MyBangumiView_Previews: PreviewProvider {
    static var previews: some View {
        MyBangumiView()
    }
}
