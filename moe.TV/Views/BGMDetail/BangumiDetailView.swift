//
//  BangumiDetailView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

struct BangumiDetailView: View {
    @Binding var bgmID:String?
    @State var bgmDetailItem:BangumiDetailModel?
    @ObservedObject var detailVM : BangumiDetailViewModel = BangumiDetailViewModel()
    
    var body: some View {
        let _ = {
            if let item = bgmID{
                getBGMDetail(id: item)
            }
            
        }()
        if let item = bgmDetailItem{
            ScrollView{
                BangumiDetailCoverTextView(item: item)
                
                Divider()
                
                ForEach(item.episodes ?? []){ ep in
                    EPCellView(epItem: ep, detailVM: detailVM)
                        .padding(10)
                }
            }
            .padding(0)
#if os(iOS) || os(tvOS)
            .fullScreenCover(isPresented:$detailVM.presentVideoView,
                             onDismiss: { },
                             content: {
                if let url = URL(string: detailVM.videoURL){
                    VideoPlayerView(url: url, seekTime: detailVM.seek,ep: detailVM.ep!)
                }else{
                    Text("Error: Video URL is empty")
                }
            })
#endif
#if os(macOS)
            .sheet(isPresented:$detailVM.presentVideoView ) {
                if let url = URL(string: detailVM.videoURL){
                    ZStack(alignment: .topLeading){
                        VideoPlayerView(url: url,seekTime: detailVM.seek,ep: detailVM.ep!)
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
            .alert("Please select a source:",isPresented: $detailVM.presentSourceSelectAlert) {
                if let ep = detailVM.ep{
                    ForEach(ep.video_files
                            ?? [], id: \.self){ item in
                        Button(item.file_name ?? "unknow source"){
                            detailVM.setVideoURL(url: fixPathNotCompete(path: item.url ?? "").addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed)!)
                        }
                    }
                }
            }
            .alert("Continue from last position?",isPresented: $detailVM.presentContinuePlayAlert) {
                Button("Yes") {
                    detailVM.setSeekTime(time: detailVM.ep!.watch_progress!.last_watch_position!)
                    detailVM.showVideoView()
                }
                Button("No, start from beginning"){
                    detailVM.setSeekTime(time: 0)
                    detailVM.showVideoView()
                }
            }
            .refreshable {
                if let item = bgmID{
                    getBGMDetail(id: item)
                }
            }
            .toolbar(content:{
                ToolbarItem(placement: .principal) {
                    HStack{
                        Spacer()
                        BangumiDetailNavTitleView(item: item)
                        Spacer()
                        BangumiDetailNavItemView(item: item)
                    }
                }
            })
            
        }
        
        
    }

                
        
    
    
    func getBGMDetail(id:String){
        print("getBGMDetail:\(id)")
        getBangumiDetail(id: id) { result, data in
            if !result{
                return
            }
            if let bgmItem = data as? BangumiDetailModel{
                self.bgmDetailItem = bgmItem
            }
        }
    }
    
}

//struct BangumiDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiDetailView(bgmID: .constant(""))
//    }
//}
