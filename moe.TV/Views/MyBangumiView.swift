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
            BangumiDetailView(bgmID: .constant(selectedItem?.id))
        }
        .sheet(isPresented: $presentSettingView, content: {
            HStack{
                Button(action: {
                    self.presentSettingView.toggle()
                }, label: {
                    Text("Close")
                }).padding(20)
                Spacer()
            }
            SettingsView()
#if os(macOS)
        .frame(width: NSApp.keyWindow?.contentView?.bounds.width ?? 500, height: NSApp.keyWindow?.contentView?.bounds.height ?? 500)
#endif
            Spacer()
        })

    }
    func getBGMList() {
        getMyBangumiList { result, data in
            if !result{
                return
            }
            self.myBGMList = []
            if let bgmList = data as? [MyBangumiItemModel]{
                self.myBGMList = bgmList
#if os(tvOS)
            let save = SaveHandler()
                save.setTopShelf(array: bgmList)
#endif
            }
        }
    }
}


struct MyBangumiView_Previews: PreviewProvider {
    static var previews: some View {
        MyBangumiView()
    }
}
