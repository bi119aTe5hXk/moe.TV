//
//  LoginView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

private enum LoginMethod: String, CaseIterable, Identifiable {
	case password
	case oauth2

	var id: String { rawValue }

	var title: String {
		switch self {
		case .password:
			return "Password"
		case .oauth2:
			return "box.moe"
		}
	}
}

struct LoginView: View {
	@ObservedObject var loginVC: LoginViewController
//	@Binding var selectedItem: BangumiItemModel?
//	@Binding var navigationPath:[AnyHashable]
	
	@State private var selectedFunc: FuncViewModel? = nil
	@State private var loginMethod: LoginMethod = .oauth2
	

    var body: some View {
        if isAlbireoAuthenticated() || loginVC.isLoginSuccessd{
			MainListView(selectedFunc: $selectedFunc, loginVC: loginVC)
        }else{
			ScrollView {
				VStack(spacing: 24) {
					Spacer(minLength: 40)

					VStack(spacing: 8) {
						Text("Connect to Albireo Services")
							.lineLimit(2)
							.fontWeight(.bold)
							.font(.title)
#if os(tvOS)
						Text("Use password login on tvOS. For box.moe login, please log in on another device and enable iCloud sync.")
							.font(.subheadline)
							.foregroundColor(.secondary)
							.multilineTextAlignment(.center)
#else
						Text("Choose a sign-in method")
							.font(.subheadline)
							.foregroundColor(.secondary)
#endif
					}

					VStack(spacing: 16) {
#if os(tvOS)
						passwordLoginFields
#else
						Picker("Login method", selection: $loginMethod) {
							ForEach(LoginMethod.allCases) { method in
								Text(method.title).tag(method)
							}
						}
						.pickerStyle(.segmented)

						switch loginMethod {
						case .password:
							passwordLoginFields
						case .oauth2:
							oauth2LoginFields
						}
#endif
					}
					.padding(20)
					.frame(maxWidth: 520)
#if !os(tvOS)
					.background(.regularMaterial)
					.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
#endif

					OfflineView().padding(10)
					Spacer(minLength: 40)
				}
				.frame(maxWidth: .infinity)
				.padding()
				.alert(
					loginVC.errorMessage,
					isPresented: $loginVC.showError
				) {
					Button("OK", role: .cancel) { }
				}
			}
        }
    }

	private var passwordLoginFields: some View {
		VStack(spacing: 12) {
			TextField("Server URL", text: $loginVC.server)
				.loginTextFieldStyle()
#if os(iOS)
				.keyboardType(.URL)
#endif
			TextField("Username", text: $loginVC.username)
				.loginTextFieldStyle()
			SecureField("Password", text: $loginVC.password)
				.loginTextFieldStyle()
				.onSubmit {
					loginVC.isLoginButtonTapped = true
				}
			Button(action: {
				loginVC.isLoginButtonTapped = true
			}, label: {
				Label("Login", systemImage: "person.crop.circle.badge.checkmark")
					.frame(maxWidth: .infinity)
			})
			.buttonStyle(.borderedProminent)
			.disabled(!loginVC.isValidUsername || !loginVC.isValidPassword || !loginVC.isValidServer)
		}
	}

	@ViewBuilder
	private var oauth2LoginFields: some View {
#if os(tvOS)
		Text("box.moe login is not available on tvOS. Please log in on another device and enable iCloud sync.")
			.multilineTextAlignment(.center)
			.padding(10)
#else
		VStack(spacing: 12) {
			TextField("API Server URL", text: $loginVC.albireoV2APIServer)
				.loginTextFieldStyle()
#if os(iOS)
				.keyboardType(.URL)
#endif
			Button(action: {
				loginVC.loginWithAlbireoV2()
			}, label: {
				Label("Login with box.moe", systemImage: "key.fill")
					.frame(maxWidth: .infinity)
			})
			.buttonStyle(.borderedProminent)
			.disabled(
				!loginVC.isValidAlbireoV2APIServer ||
				!loginVC.isAlbireoV2ClientConfigured
			)
		}
#endif
	}
}

private extension View {
	func loginTextFieldStyle() -> some View {
		self
#if !os(macOS)
			.textInputAutocapitalization(.never)
#endif
			.autocorrectionDisabled()
#if !os(tvOS)
			.textFieldStyle(.roundedBorder)
#endif
	}
}

//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView(viewModel: LoginViewModel())
//    }
//}
