#if os(iOS)
import SwiftUI
import WebKit
import SafariServices

// MARK: - Public API (choose how to show web content)

/// Pick how to show a URL.
/// - `.inlineWK`: Embeddable WKWebView (best for split view layouts).
/// - `.safari`: In-app Safari view controller (best for reusing Safari cookies / logged-in state).
///
/// NOTE: Apple intends `SFSafariViewController` to be presented (sheet/fullScreenCover), not embedded.
/// If you need a persistent side-by-side panel, use `.inlineWK`.
enum WebViewMode {
    case inlineWK
    case safari
}

/// A SwiftUI web container where the caller chooses the mode.
struct WebView: View {
    let url: URL
    var mode: WebViewMode = .inlineWK

    var body: some View {
        switch mode {
        case .inlineWK:
            WKInlineWebView(url: url)
        case .safari:
            // If you place SafariView in navigation, Catalyst may show it like a new window/page.
            // Prefer presenting via `.safariSheet(...)`.
            SafariView(url: url)
                // SafariViewController doesn't navigate via update; force recreation when URL changes.
                .id(url.absoluteString)
        }
    }
}

// MARK: - Sheet presenter for Safari

/// Wrapper so we can present Safari via `.sheet(item:)`.
struct SafariURL: Identifiable, Equatable {
    let url: URL
    var id: String { url.absoluteString }
}

extension View {
    /// Present an in-app Safari sheet (uses the system Safari cookie jar).
    func safariSheet(url: Binding<SafariURL?>) -> some View {
        self.sheet(item: url) { item in
            SafariView(url: item.url)
        }
    }
}

// MARK: - Inline WKWebView (embeddable)

private struct WKInlineWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Avoid reloading the same URL on every SwiftUI update.
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
}

// MARK: - In-app Safari (cookie-sharing)

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.dismissButtonStyle = .close
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // Navigation is handled by recreating the controller via .id(...) in WebView or via sheet presentation.
    }
}

#endif
