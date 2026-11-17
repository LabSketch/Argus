import Foundation
import ArgusCore

public final class MCPToolRegistry {
    private let registry: ToolRegistry
    private let ipcClient: IPCClient

    public init(ipcClient: IPCClient) {
        self.registry = defaultToolRegistry()
        self.ipcClient = ipcClient
    }

    public var toolNames: [String] {
        registry.toolNames
    }

    public var allTools: [any Tool] {
        registry.allTools
    }

    public func tool(named name: String) -> (any Tool)? {
        registry.tool(named: name)
    }

    public func handleCall(name: String, arguments: JSONValue?) async throws -> JSONValue {
        guard let tool = registry.tool(named: name) else {
            throw RPCError.methodNotFound
        }

        switch name {
        case "navigate":
            return try await handleNavigate(arguments: arguments)
        case "evaluate_js":
            return try await handleEvaluateJS(arguments: arguments)
        case "get_page_info":
            return try await handleGetPageInfo()
        case "close_page":
            return try await handleClosePage()
        default:
            throw RPCError.methodNotFound
        }
    }

    private func handleNavigate(arguments: JSONValue?) async throws -> JSONValue {
        guard let args = arguments?.asObject,
              let urlString = args["url"]?.asString else {
            throw RPCError.invalidParams
        }

        guard let (url, _) = ToolSchemas.validateURL(urlString) else {
            throw RPCError.applicationError(code: -32001, message: "Invalid or disallowed URL")
        }

        let request = RPCRequest(method: "navigate", params: .object(["url": .string(url.absoluteString)]))
        let reply = try await ipcClient.sendRequest(request)

        if let error = reply.error {
            throw NSError(domain: "MCPToolRegistry", code: error.code, userInfo: [NSLocalizedDescriptionKey: error.message])
        }

        return reply.result ?? .null
    }

    private func handleEvaluateJS(arguments: JSONValue?) async throws -> JSONValue {
        guard let args = arguments?.asObject,
              let script = args["script"]?.asString else {
            throw RPCError.invalidParams
        }

        guard ToolSchemas.validateScript(script) else {
            throw RPCError.applicationError(code: -32002, message: "Script exceeds maximum size")
        }

        let request = RPCRequest(method: "evaluate_js", params: .object(["script": .string(script)]))
        let reply = try await ipcClient.sendRequest(request)

        if let error = reply.error {
            throw NSError(domain: "MCPToolRegistry", code: error.code, userInfo: [NSLocalizedDescriptionKey: error.message])
        }

        return reply.result ?? .null
    }

    private func handleGetPageInfo() async throws -> JSONValue {
        let request = RPCRequest(method: "get_page_info", params: nil)
        let reply = try await ipcClient.sendRequest(request)

        if let error = reply.error {
            throw NSError(domain: "MCPToolRegistry", code: error.code, userInfo: [NSLocalizedDescriptionKey: error.message])
        }

        return reply.result ?? .null
    }

    private func handleClosePage() async throws -> JSONValue {
        let request = RPCRequest(method: "close_page", params: nil)
        let reply = try await ipcClient.sendRequest(request)

        if let error = reply.error {
            throw NSError(domain: "MCPToolRegistry", code: error.code, userInfo: [NSLocalizedDescriptionKey: error.message])
        }

        return reply.result ?? .null
    }
}