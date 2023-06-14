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
                    Menu(content: {
                        Button(action: {
                            clearCookie()
                            exit(0)
                        }, label: {
                            Text("Logout & exit")
                        })
                        
                    }, label: {
                        Image(systemName: "gear")
                    })
                    
                })
            BangumiDetailView(bangumiItem: nil)
        }
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
