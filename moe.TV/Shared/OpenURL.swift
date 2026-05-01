//
//  OpenURL.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/02.
//

import Foundation

#if os(iOS) || os(visionOS)
import UIKit
import SafariServices
import AuthenticationServices

private func topMostViewController(base: UIViewController? = UIApplication.shared.firstKeyWindow?.rootViewController) -> UIViewController? {
    if let nav = base as? UINavigationController {
        return topMostViewController(base: nav.visibleViewController)
    }
    if let tab = base as? UITabBarController {
        return topMostViewController(base: tab.selectedViewController)
    }
    if let presented = base?.presentedViewController {
        return topMostViewController(base: presented)
    }
    return base
}

func openURLInApp(urlString: String) {
    guard let url = URL(string: urlString) else { return }
	let vc = SFSafariViewController(url: url)
#if !os(visionOS)
	vc.dismissButtonStyle = .close
#endif
	topMostViewController()?.present(vc, animated: true)
}

func openURL(urlString: String) {
    openURLInApp(urlString: urlString)
}

// MARK: - OAuth

final class OAuthSessionManager: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthSessionManager()

    private var session: ASWebAuthenticationSession?

    func start(urlString: String, callbackScheme: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: urlString) else { return }

        // Keep a strong reference to the session; otherwise it may be deallocated and immediately cancel.
        let s = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
            // Release session after finishing.
            self.session = nil

            if let callbackURL {
                completion(.success(callbackURL))
            } else if let error {
                completion(.failure(error))
            }
        }

        s.presentationContextProvider = self
        // If you want a fresh login every time, consider enabling ephemeral session.
        // s.prefersEphemeralWebBrowserSession = true

        self.session = s
        _ = s.start()
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.firstKeyWindow ?? ASPresentationAnchor()
    }
}

extension UIApplication {
    var firstKeyWindow: UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .first?.keyWindow
    }
}
#endif

#if os(macOS)
import Cocoa
func openURLInApp(urlString:String){
    openURL(urlString: urlString)
}
func openURL(urlString:String){
    if let url = URL(string: urlString){
        NSWorkspace.shared.open(url)
    }
}
#endif
