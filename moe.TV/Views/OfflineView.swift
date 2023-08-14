//
//  OfflineView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/14.
//

import SwiftUI

struct OfflineView: View {
    @State private var showDownloadList = false
    
    var body: some View {
        Button(action: {
            self.showDownloadList.toggle()
        }, label: {
            Text("Show download list")
        })
        .padding(10)
        .sheet(isPresented: self.$showDownloadList, content: {
            HStack{
#if !os(tvOS)
                Button(action: {
                    self.showDownloadList.toggle()
                }, label: {
                    Text("Close")
                }).padding(20)
                Spacer()
#endif
            }
            DownloadListView( dlListVM: DownloadListViewModel())
                .environmentObject(DownloadManager())
                .environmentObject(OfflinePlaybackManager())
        })
    }
}

struct OfflineView_Previews: PreviewProvider {
    static var previews: some View {
        OfflineView()
    }
}
