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
			return "OAuth2"
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
						Text("Choose a sign-in method")
							.font(.subheadline)
							.foregroundColor(.secondary)
					}

					VStack(spacing: 16) {
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
		Text("Albireo OAuth2 login is not available on tvOS. Please log in on another device and enable iCloud sync.")
			.multilineTextAlignment(.center)
			.padding(10)
#else
		VStack(spacing: 12) {
			TextField("Authorization Server URL", text: $loginVC.albireoV2AuthorizationServer)
				.loginTextFieldStyle()
#if os(iOS)
				.keyboardType(.URL)
#endif
			TextField("API Server URL", text: $loginVC.albireoV2APIServer)
				.loginTextFieldStyle()
#if os(iOS)
				.keyboardType(.URL)
#endif
			TextField("OAuth2 Client ID", text: $loginVC.albireoV2OAuthClientID)
				.loginTextFieldStyle()
			TextField("OAuth2 Redirect Host", text: $loginVC.albireoV2OAuthRedirectHost)
				.loginTextFieldStyle()
			Button(action: {
				loginVC.loginWithAlbireoV2()
			}, label: {
				Label("Login with OAuth2", systemImage: "key.fill")
					.frame(maxWidth: .infinity)
			})
			.buttonStyle(.borderedProminent)
			.disabled(
				!loginVC.isValidAlbireoV2AuthorizationServer ||
				!loginVC.isValidAlbireoV2APIServer ||
				!loginVC.isValidAlbireoV2ClientID ||
				!loginVC.isValidAlbireoV2RedirectHost
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
			.textFieldStyle(.roundedBorder)
	}
}

//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView(viewModel: LoginViewModel())
//    }
//}
