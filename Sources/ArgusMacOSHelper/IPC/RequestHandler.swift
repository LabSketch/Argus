import Foundation
import ArgusCore

@available(macOS 26.0, *)
@MainActor
public final class RequestHandler: @unchecked Sendable {
    private let session: BrowserSession
    private let proxy: WebPageProxy

    public init(session: BrowserSession) {
        self.session = session
        self.proxy = WebPageProxy(session: session)
    }

    @MainActor
    public func handle(request: RPCRequest) async throws -> RPCReply {
        switch request.method {
        case "navigate":
            return try await handleNavigate(request: request)
        case "evaluate_js":
            return try await handleEvaluateJS(request: request)
        case "get_page_info":
            return try await handleGetPageInfo(request: request)
        case "close_page":
            return try await handleClosePage(request: request)
        default:
            return RPCReply.failure(id: request.id, error: .methodNotFound)
        }
    }

    private func handleNavigate(request: RPCRequest) async throws -> RPCReply {
        guard let params = request.params?.asObject,
              let urlString = params["url"]?.asString,
              let url = URL(string: urlString) else {
            return RPCReply.failure(id: request.id, error: .invalidParams)
        }

        let result: NavigationResult
        do {
            result = try await withCheckedThrowingContinuation { continuation in
                Task { @MainActor in
                    do {
                        let navResult = try await self.proxy.navigate(to: url)
                        continuation.resume(returning: navResult)
                    } catch {
                        continuation.resume(returning: NavigationResult(success: false, error: error.localizedDescription))
                    }
                }
            }
        } catch {
            return RPCReply.failure(id: request.id, error: .internalError)
        }

        let resultValue: JSONValue = .object([
            "success": .bool(result.success),
            "finalURL": result.finalURL.map { .string($0) } ?? .null,
            "title": result.title.map { .string($0) } ?? .null,
            "error": result.error.map { .string($0) } ?? .null
        ])

        return RPCReply.success(id: request.id, result: resultValue)
    }

    private func handleEvaluateJS(request: RPCRequest) async throws -> RPCReply {
        guard let params = request.params?.asObject,
              let script = params["script"]?.asString else {
            return RPCReply.failure(id: request.id, error: .invalidParams)
        }

        let result: JSONValue
        do {
            result = try await withCheckedThrowingContinuation { continuation in
                Task { @MainActor in
                    do {
                        let jsResult = try await self.proxy.evaluateJavaScript(script)
                        continuation.resume(returning: jsResult)
                    } catch {
                        continuation.resume(returning: JSONValue.object(["error": .string(error.localizedDescription)]))
                    }
                }
            }
        } catch {
            return RPCReply.failure(id: request.id, error: .internalError)
        }

        return RPCReply.success(id: request.id, result: result)
    }

    @MainActor
    private func handleGetPageInfo(request: RPCRequest) async throws -> RPCReply {
        let pageInfo = proxy.getPageInfo()
        let resultValue: JSONValue = .object([
            "url": pageInfo.url.map { .string($0) } ?? .null,
            "title": pageInfo.title.map { .string($0) } ?? .null,
            "isLoading": .bool(pageInfo.isLoading)
        ])

        return RPCReply.success(id: request.id, result: resultValue)
    }

    @MainActor
    private func handleClosePage(request: RPCRequest) async throws -> RPCReply {
        proxy.close()
        let resultValue: JSONValue = .object([
            "success": .bool(true),
            "error": .null
        ])
        return RPCReply.success(id: request.id, result: resultValue)
    }
}