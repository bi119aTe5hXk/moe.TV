//
//  FavoriteStatusView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2025/04/30.
//
import SwiftUI

struct FavoriteStatusView: View {
	@Binding var albireo_favorite_status:Int?
	@Binding var bgmtv_favorite_status:Int?
	
	var body: some View {
		VStack{
			Text("Albireo")
			BGMStatusTextView(status: $albireo_favorite_status)
				.padding(10)
		}
		Spacer()
		if isBGMTVlogined() {
			Divider()
			Spacer()
			VStack{
				Text("Bgm.tv")
				BGMStatusTextView(
					status:$bgmtv_favorite_status
				)
				.padding(10)
			}
			Spacer()
		}
	}
}
