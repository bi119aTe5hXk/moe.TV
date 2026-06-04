//
//  TVSidebar.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2026/04/30.
//
import SwiftUI
#if os(tvOS)
struct TVSidebar: View {
	@Binding var selectedFunc: FuncViewModel?
	@State var presentSettingView = false

	var body: some View {
		VStack(alignment: .leading, spacing: 24) {
			Text("moe.TV")
				.font(.title2)
			ForEach(FuncViewModel.allCases) { item in
				Button {
					selectedFunc = item
				} label: {
					Text(item.localizedName)
						.font(.title3)
				}
				.buttonStyle(.plain)
			}
			Button{
				self.presentSettingView = true
			}label: {
				Text("Settings")
					.font(.title3)
			}
			.buttonStyle(.plain)
			
			Spacer()
		}
		.padding(.top, 80)
		.padding(.horizontal, 40)
		.fullScreenCover(isPresented: $presentSettingView) {
			SettingsView(settingsVC: SettingsViewController())
				.background().edgesIgnoringSafeArea(.all)
		}
	}
}
#endif
