import Testing
import Foundation
@testable import ArgusCore

@Suite("BrowserSession Tests")
struct BrowserSessionTests {
    @Test("Initial state")
    func initialState() {
        let session = BrowserSession()
        #expect(session.url == nil)
        #expect(session.title == nil)
        #expect(session.loadingState == false)
    }

    @Test("Close resets state")
    func close() async {
        let session = BrowserSession()
        session.close()
        
        #expect(session.url == nil)
        #expect(session.title == nil)
        #expect(session.loadingState == false)
    }
}

@Suite("WebPageProxy Tests")
struct WebPageProxyTests {
    @Test("Proxy delegates to session")
    func delegation() async {
        let session = BrowserSession()
        let proxy = WebPageProxy(session: session)
        
        let pageInfo = proxy.getPageInfo()
        #expect(pageInfo.url == nil)
        #expect(pageInfo.title == nil)
        #expect(pageInfo.isLoading == false)
    }
}