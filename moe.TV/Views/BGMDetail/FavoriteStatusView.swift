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
		HStack(alignment: .top, spacing: 18) {
			statusColumn("Albireo", status: $albireo_favorite_status)
			if isBGMTVlogined() {
				statusColumn("Bgm.tv", status: $bgmtv_favorite_status)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	private func statusColumn(_ title: LocalizedStringKey, status: Binding<Int?>) -> some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(title)
				.font(.caption)
				.foregroundStyle(.secondary)
			BGMStatusTextView(status: status)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}
