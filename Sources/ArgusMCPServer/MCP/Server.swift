import Foundation
import ArgusCore

public final class MCPServer {
    private let toolRegistry: MCPToolRegistry
    private let encoder = JSONMessageEncoder()
    private let stderr = FileHandle.standardError

    public init(toolRegistry: MCPToolRegistry) {
        self.toolRegistry = toolRegistry
    }

    public func run() async {
        log("Argus MCP Server starting...")
        
        let tools = toolRegistry.toolNames
        log("Available tools: \(tools.joined(separator: ", "))")

        while true {
            guard let line = readLine() else { break }
            
            do {
                let requestData = Data(line.utf8)
                let request = try encoder.decode(RPCRequest.self, from: requestData)
                let reply = try await handleRequest(request)
                let replyData = try encoder.encode(reply)
                let replyString = String(data: replyData, encoding: .utf8) ?? "{}"
                print(replyString)
            } catch {
                let errorReply = RPCReply.failure(id: UUID(), error: .parseError)
                if let replyData = try? encoder.encode(errorReply),
                   let replyString = String(data: replyData, encoding: .utf8) {
                    print(replyString)
                }
            }
        }
    }

    private func log(_ message: String) {
        let data = Data((message + "\n").utf8)
        stderr.write(data)
    }

    private func handleRequest(_ request: RPCRequest) async throws -> RPCReply {
        switch request.method {
        case "initialize":
            return handleInitialize(request)
        case "tools/list":
            return handleToolsList(request)
        case "tools/call":
            return try await handleToolCall(request)
        default:
            return RPCReply.failure(id: request.id, error: .methodNotFound)
        }
    }

    private func handleInitialize(_ request: RPCRequest) -> RPCReply {
        let result: JSONValue = .object([
            "protocolVersion": "2024-11-05",
            "capabilities": .object(["tools": .object([:])]),
            "serverInfo": .object([
                "name": "Argus",
                "version": "0.1.0"
            ])
        ])
        return RPCReply.success(id: request.id, result: result)
    }

    private func handleToolsList(_ request: RPCRequest) -> RPCReply {
        let tools = toolRegistry.allTools.map { tool in
            JSONValue.object([
                "name": .string(tool.name),
                "description": .string(tool.description),
                "inputSchema": tool.inputSchema,
                "outputSchema": tool.outputSchema
            ])
        }
        let result: JSONValue = .object(["tools": .array(tools)])
        return RPCReply.success(id: request.id, result: result)
    }

    private func handleToolCall(_ request: RPCRequest) async throws -> RPCReply {
        guard let params = request.params?.asObject,
              let name = params["name"]?.asString else {
            return RPCReply.failure(id: request.id, error: .invalidParams)
        }

        let arguments = params["arguments"]

        do {
            let result = try await toolRegistry.handleCall(name: name, arguments: arguments)
            return RPCReply.success(id: request.id, result: result)
        } catch let error as NSError {
            let rpcError = RPCError.applicationError(code: error.code, message: error.localizedDescription)
            return RPCReply.failure(id: request.id, error: rpcError)
        } catch {
            let rpcError = RPCError.internalError
            return RPCReply.failure(id: request.id, error: rpcError)
        }
    }
}