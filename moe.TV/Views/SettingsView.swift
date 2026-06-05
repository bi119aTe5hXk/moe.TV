//
//  SettingsView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/14.
//

import SwiftUI

struct SettingsView: View {
//    @State private var syncWithBGMTV = isBGMTVlogined()
    @State private var showDownloadList: Bool = false
	@State private var landscapePlayback: Bool = false
	@State private var showBgmtvWebWhilePlaying: Bool = false
	@State private var useCustomPlayerUI: Bool = false
	@State private var hideUnreleasedEps: Bool = false
	@State private var setWatchedWhenFinishedFinalEP: Bool = false
    @State private var checkFavStatusConflict: Bool = false


//    @Binding var listVM:BangumiListViewModel
//    @Binding var loginVM:LoginViewModel
//    @Binding var myBGMVM:MyBangumiViewModel
	@ObservedObject var settingsVC:SettingsViewController

	var body: some View {
		NavigationStack{
			VStack{
				HStack{
					Text("Settings")
						.font(.largeTitle).bold()
						.padding(10)
					Spacer()
				}

				List{
					Section(header: Text("Bgm.tv") ) {
#if os(tvOS)
						Text("Bgm.tv setting on tvOS is not supported. But you can use iOS or macOS device to setup and will do sync with bgm.tv on tvOS.")
#endif
						Toggle(isOn: $settingsVC.isBGMSyncEnabled){
							Text("Sync status with bgm.tv")
						}
#if os(tvOS)
						.disabled(true)
#endif
						.onAppear(){
							if settingsVC.isBGMSyncEnabled{
								settingsVC.getBGMUserInfo()
							}
						}
						.onChange(of: settingsVC.isBGMSyncEnabled, initial: false) { newValue in
//							if !syncWithBGMTV{
//								print("syncWithBGMTV is false, do nothing")
//								return
//							}
							print("newValue: \(newValue)")
							if newValue {
								if !isBGMTVlogined(){
									startBGMTVLogin()
								}
							}else{
								settingsVC.showLogoutBGMTVAlert()
							}
						}
						.alert(isPresented: $settingsVC.presentLogoutBGMTVAlert) {
							Alert(
								title: Text("Are you sure you want to logout from bgm.tv?"),
								primaryButton: .destructive(Text("Logout")) {
									settingsVC.isBGMSyncEnabled = false
									logoutBGMTV()
									settingsVC.isBGMUserInfoReady = false
								},
								secondaryButton: .cancel(){
									settingsVC.isBGMSyncEnabled = true
								}
							)
						}
						if settingsVC.isBGMUserInfoReady{
							HStack{
								VStack{
									HStack{
										Text("Nickname: \(settingsVC.bgmNickname)")
										Spacer()
									}
									HStack{
										Text("Username: \(settingsVC.bgmUsername)")
										Spacer()
									}
									HStack{
										Text("ID: \(String(settingsVC.bgmID))")
										Spacer()
									}

								}
								Spacer()
								AsyncImage(url: URL(string: settingsVC.avatar_url)) { image in
									image.resizable()
										.frame(width: 50, height: 50)
										.foregroundColor(.white)
								} placeholder: {
									ProgressView()
								}
							}
							HStack{
								Text("Sign: \(settingsVC.bgmSign)")
								Spacer()
							}
						}

					}

					Section(header: Text("Preferences")) {
						Toggle("Hide unrelease/empty EPs",isOn: $hideUnreleasedEps)
							.onAppear(){
								self.hideUnreleasedEps = settingsVC.settingsHandler.getHideUnreleaseEPs()
							}
							.onChange(of: hideUnreleasedEps, initial: false) { newValue in
								settingsVC.settingsHandler.setHideUnreleaseEPs(isEnabled: newValue)
							}

						Toggle("Set watched when finished the final EP",isOn: $setWatchedWhenFinishedFinalEP)
							.onAppear(){
								self.setWatchedWhenFinishedFinalEP = settingsVC.settingsHandler.getSetWatchedWhenFinishedFinalEP()
							}
							.onChange(of: setWatchedWhenFinishedFinalEP, initial: false) { newValue in
								settingsVC.settingsHandler.setSetWatchedWhenFinishedFinalEP(isEnabled: newValue)
							}
                        
                        Toggle("Check favorite status conflict", isOn: $checkFavStatusConflict)
                            .onAppear(){
                                self.checkFavStatusConflict = settingsVC.settingsHandler.getCheckFavStatusConflict()
                            }
                            .onChange(of: checkFavStatusConflict, initial: false) { newValue in
                                settingsVC.settingsHandler.setCheckFavStatusConflict(isEnabled: newValue)
                            }


#if os(iOS)
						if UIDevice.current.userInterfaceIdiom == .phone{
							Toggle("Force landscape while playing (iPhone only)", isOn: $landscapePlayback)
								.onAppear(){
									self.landscapePlayback = settingsVC.settingsHandler.getLandscapePlayback()
								}
								.onChange(of: landscapePlayback, initial: false, perform: { value in
									settingsVC.settingsHandler.setLandscapePlayback(isEnabled: value)
								})
						}else{
							//Do not show this setting for iPhone, NO NOT REMOVE THIS!
							Toggle("Show Bgm.tv while playing (may result in spoilers!)", isOn: $showBgmtvWebWhilePlaying)
								.onAppear(){
									self.showBgmtvWebWhilePlaying = settingsVC.settingsHandler
										.getShowBgmtvWebWhilePlaying()
								}
								.onChange(of: showBgmtvWebWhilePlaying, initial: false, perform: { value in
									settingsVC.settingsHandler
										.setShowBgmtvWebWhilePlaying(
											isEnabled: value
										)
								})
						}
#endif
#if os(macOS)

						Toggle("Show Bgm.tv while playing (may result in spoilers!)", isOn: $showBgmtvWebWhilePlaying)
							.onAppear(){
								self.showBgmtvWebWhilePlaying = settingsVC.settingsHandler
									.getShowBgmtvWebWhilePlaying()
							}
							.onChange(of: showBgmtvWebWhilePlaying, initial: false, perform: { value in
								settingsVC.settingsHandler
									.setShowBgmtvWebWhilePlaying(
										isEnabled: value
									)
							})

#endif
#if !os(tvOS)
						Toggle("Use custom player UI", isOn: $useCustomPlayerUI)
							.onAppear(){
								self.useCustomPlayerUI = settingsVC.settingsHandler.getUseCustomPlayerUI()
							}
							.onChange(of: useCustomPlayerUI, initial: false) { newValue in
								settingsVC.settingsHandler.setUseCustomPlayerUI(isEnabled: newValue)
							}
#endif

						Picker(
							"Default playbck speed",
							selection: $settingsVC.playbackRate
						) {
							Text("0.5x").tag(0.5)
							Text("1x").tag(1.0)
							Text("1.25x").tag(1.25)
							Text("1.5x").tag(1.5)
							Text("2x").tag(2.0)
						}
						.onAppear(){
							self.settingsVC.playbackRate = settingsVC.settingsHandler.getPlaybackRate()
							if settingsVC.playbackRate == 0.0{
								self.settingsVC.playbackRate = 1.0
							}
						}
						.onChange(of: settingsVC.playbackRate, initial: false, perform: { value in
							settingsVC.settingsHandler.setPlaybackRate(rate: value)
						})

							//TODO: mark playing as want in bgm.tv options
							//TODO: hide not-onair items switch
					}

					Section(header: Text("Download")) {
						Button {
							self.showDownloadList.toggle()
						} label: {
							Text("Open download manager")
						}
						.sheet(
							isPresented: self.$showDownloadList,
							content: {
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
								DownloadListView(
									dlListVC: DownloadListViewController()
								)
								.environmentObject(DownloadManager())
								.environmentObject(OfflinePlaybackManager())
							})
					}

					Section(header: Text("Playback History")){
						Button{
							settingsVC.presentClearHistoryAlert.toggle()
						}label: {
							Text("Clear playback history")
						}
						.alert( isPresented: $settingsVC.presentClearHistoryAlert) {
							Alert(
								title: Text("Are you sure to delete all playback history?"),
								primaryButton: .destructive(Text("Clear history")){
									settingsVC.settingsHandler
										.setPlaybackHistory(history: [])
								},
								secondaryButton: .cancel()
							)
						}
					}

					Section(header: Text("Debug")) {
						NavigationLink{
							DebugView(debugVC: DebugViewController())
						}label: {
							Text("Debug menu")
						}
					}

					Section(header: Text("Sign out"),footer: Text("Version:\(settingsVC.getAppVersion()), Build:\(settingsVC.getBuildVersion())")) {
						Button(action: {
							settingsVC.showLogoutAlbireoAlert()
						}, label: {
							Text("Logout & Exit").foregroundColor(.red)
						}).padding(10)

							.alert(isPresented: $settingsVC.presentLogoutAlbireoAlert) {
								Alert(
									title: Text("Are you sure you want to logout and exit app?"),
									primaryButton: .destructive(Text("Logout")) {
										logoutAlbireoServer { result, data in

										}
											//listVM.myBGMList = []
											//                                    loginVM.presentLoginView = true //TODO: show login view after logout
											//                                    loginVM.isLoginSuccessd = false
											//myBangumiVM.toggleSettingView()
										exit(0) //TODO: logout without exit
									},
									secondaryButton: .cancel()
								)
							}
					}
				}
			}
		}
	}

    
    
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView(loginViewModel: LoginViewModel())
//    }
//}
