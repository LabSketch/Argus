import Foundation
import WebKit
import ArgusCore

@MainActor
@available(macOS 26.0, *)
public final class BrowserSession {
    private var webPage: WebPage?
    private var currentURL: URL?
    private var currentTitle: String?
    private var isLoading: Bool = false

    public init() {}

    public var url: URL? { currentURL }
    public var title: String? { currentTitle }
    public var loadingState: Bool { isLoading }

    public func navigate(to url: URL) async throws -> NavigationResult {
        if webPage == nil {
            webPage = WebPage()
        }

        isLoading = true
        currentURL = url
        webPage?.load(url)

        try await Task.sleep(nanoseconds: 500_000_000)

        currentTitle = webPage?.title
        isLoading = webPage?.isLoading ?? false

        return NavigationResult(
            success: true,
            finalURL: webPage?.url?.absoluteString ?? url.absoluteString,
            title: currentTitle,
            error: nil
        )
    }

    public func evaluateJavaScript(_ script: String) async throws -> JSONValue {
        guard webPage != nil else {
            throw NSError(domain: "BrowserSession", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active WebPage session"])
        }

        return JSONValue.object(["error": "JavaScript evaluation not supported by WebPage API (macOS 26+)"])
    }

    public func getPageInfo() -> PageInfo {
        PageInfo(url: currentURL?.absoluteString, title: currentTitle, isLoading: isLoading)
    }

    public func close() {
        webPage = nil
        currentURL = nil
        currentTitle = nil
        isLoading = false
    }
}

@MainActor
@available(macOS 26.0, *)
public final class WebPageProxy {
    private let session: BrowserSession

    public init(session: BrowserSession) {
        self.session = session
    }

    public func navigate(to url: URL) async throws -> NavigationResult {
        try await session.navigate(to: url)
    }

    public func evaluateJavaScript(_ script: String) async throws -> JSONValue {
        try await session.evaluateJavaScript(script)
    }

    public func getPageInfo() -> PageInfo {
        session.getPageInfo()
    }

    public func close() {
        session.close()
    }
}