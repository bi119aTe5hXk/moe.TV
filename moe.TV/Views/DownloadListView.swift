//
//  DownloadListView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/06.
//

import SwiftUI
struct DownloadListView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @ObservedObject var dlListVM: DownloadListViewModel
    
    var body: some View {
        List{
            if dlListVM.fileList.count > 0{
                ForEach(dlListVM.fileList, id: \.self){ item in
                    Button {
                        let playerItem = downloadManager.getVideoFileAsset(filename: item.lastPathComponent)
                        dlListVM.showVideoView(path: playerItem!)
                    } label: {
                        Text(item.lastPathComponent)
                    }
                    
                }
                .onDelete(perform: delete)
                .refreshable {
                    getDownloadList()
                }
            }else{
                Text("No video cached.")
            }
        }.onAppear(){
            getDownloadList()
        }
        
#if os(iOS) || os(tvOS)
            .fullScreenCover(isPresented:$dlListVM.presentVideoView,
                             onDismiss: { },
                             content: {
                if let path = dlListVM.videoFilePath{
                    VideoPlayerView(url: path, seekTime: 0,ep: nil,isOffline: true)
                }
            })
#endif
#if os(macOS)
            .sheet(isPresented:$dlListVM.presentVideoView ) {
                if let path = dlListVM.videoFilePath{
                    ZStack(alignment: .topLeading){
                        VideoPlayerView(url: path, seekTime: 0,ep: nil,isOffline: true)
                            .frame(width: NSApp.keyWindow?.contentView?.bounds.width ?? 500, height: NSApp.keyWindow?.contentView?.bounds.height ?? 500)
                        //TODO: better close button for macOS
                        Button(action: {
                            detailVM.closePlayer()
                        }, label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .renderingMode(.template)
                                .frame(width: 15, height: 15)
                                .foregroundColor(.white)
                        }).buttonStyle(.plain)
                    }
                    
                }else{
                    Text("Error: Video URL is empty")
                }
            }
#endif
        
    }
    
    func delete(at offsets: IndexSet) {
        if let deleteItem = offsets.map({ dlListVM.fileList[$0] }).first {
            print("delete:\(deleteItem.lastPathComponent)")
            downloadManager.deleteFile(fileName: deleteItem.lastPathComponent)
        }
    }
    
    func getDownloadList(){
        downloadManager.getDownloadList { list in
            print(list)
            dlListVM.setFileList(list: list)
        }
    }
}

//struct DownloadListView_Previews: PreviewProvider {
//    static var previews: some View {
//        DownloadListView()
//    }
//}
