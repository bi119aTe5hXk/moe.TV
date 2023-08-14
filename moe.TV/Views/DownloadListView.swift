//
//  DownloadListView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/06.
//

import SwiftUI
struct DownloadListView: View {
    @EnvironmentObject var downloadManager:DownloadManager
    @EnvironmentObject var offlinePBM:OfflinePlaybackManager
    @ObservedObject var dlListVM:DownloadListViewModel
    
    var body: some View {
        List{
            if dlListVM.fileList.count > 0{
                ForEach(dlListVM.fileList, id: \.self){ item in
                    Button {
                        let playerItem = downloadManager.getVideoFileAsset(filename: item.lastPathComponent)
                        dlListVM.showVideoView(path: playerItem!,filename: item.lastPathComponent)
                    } label: {
                        HStack{
                            Text(item.lastPathComponent)
                            Spacer()
                            if let status = offlinePBM.getPlayBackStatus(filename: item.lastPathComponent){
                                Text("\(secondsToHoursMinutesSeconds(seconds: status.position))")
                            }
                        }
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
                    VideoPlayerView(url: path,
                                    seekTime: dlListVM.playbackPosition ?? 0,
                                    ep: nil,
                                    isOffline: true,
                                    filename: dlListVM.fileName)
                }
            })
#endif
#if os(macOS)
            .sheet(isPresented:$dlListVM.presentVideoView ) {
                if let path = dlListVM.videoFilePath{
                    ZStack(alignment: .topLeading){
                        VideoPlayerView(url: path,
                                        seekTime: dlListVM.playbackPosition ?? 0,
                                        ep: nil,
                                        isOffline: true,
                                        filename: dlListVM.fileName)
                            .frame(width: NSApp.keyWindow?.contentView?.bounds.width ?? 500, height: NSApp.keyWindow?.contentView?.bounds.height ?? 500)
                        //TODO: better close button for macOS
                        Button(action: {
                            dlListVM.closePlayer()
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
            offlinePBM.deletePlayBackStatus(filename: deleteItem.lastPathComponent)
        }
    }
    
    func getDownloadList(){
        downloadManager.getDownloadList { list in
            //print(list)
            dlListVM.setFileList(list: list)
        }
    }
    
    func secondsToHoursMinutesSeconds(seconds: Double) -> String {
        let (hr,  minf) = modf(seconds / 3600)
        let (min, secf) = modf(60 * minf)
        return "\(formatDoubleToString(number: hr)):\(formatDoubleToString(number: min)):\(formatDoubleToString(number:60 * secf))"
    }
    
    func formatDoubleToString(number:Double) -> String{
        if number > 0 && number < 10{
            return "0\(Int(number))"
        }else if number > 10{
            return "\(Int(number))"
        }else{
            return "00"
        }
    }
}

//struct DownloadListView_Previews: PreviewProvider {
//    static var previews: some View {
//        DownloadListView()
//    }
//}
