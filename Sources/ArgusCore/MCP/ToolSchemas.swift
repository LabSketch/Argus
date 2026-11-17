import Foundation

public protocol Tool: Sendable {
    var name: String { get }
    var description: String { get }
    var inputSchema: JSONValue { get }
    var outputSchema: JSONValue { get }
}

public struct ToolRegistry {
    private var tools: [String: any Tool] = [:]

    public init() {}

    public mutating func register(_ tool: any Tool) {
        tools[tool.name] = tool
    }

    public func tool(named name: String) -> (any Tool)? {
        tools[name]
    }

    public var allTools: [any Tool] {
        Array(tools.values)
    }

    public var toolNames: [String] {
        Array(tools.keys).sorted()
    }
}

public enum ToolSchemas {
    public static let maxScriptSize = 10_000
    public static let maxResultSize = 100_000
    public static let navigationTimeoutSeconds = 30

    public static let allowedSchemes: Set<String> = ["https"]

    private final class HostsStorage: @unchecked Sendable {
        private let lock = NSLock()
        private var hosts: Set<String> = []

        var value: Set<String> {
            get { lock.withLock { hosts } }
            set { lock.withLock { hosts = newValue } }
        }
    }

    private static let allowedHostsStorage = HostsStorage()

    public static var allowedHosts: Set<String> {
        get { allowedHostsStorage.value }
        set { allowedHostsStorage.value = newValue }
    }

    public static func validateURL(_ urlString: String) -> (URL, String)? {
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased(),
              allowedSchemes.contains(scheme) else {
            return nil
        }

        let hosts = allowedHosts
        if !hosts.isEmpty,
           let host = url.host?.lowercased(),
           !hosts.contains(host) {
            return nil
        }

        return (url, "\(scheme)://\(url.host ?? "")")
    }

    public static func validateScript(_ script: String) -> Bool {
        script.utf8.count <= maxScriptSize
    }
}

public struct NavigateTool: Tool {
    public let name = "navigate"
    public let description = "Load a permitted URL and return navigation status, final URL, and title."

    public let inputSchema: JSONValue = .object([
        "type": "object",
        "properties": .object([
            "url": .object([
                "type": "string",
                "format": "uri",
                "description": "The URL to navigate to. Must use an allowed scheme (https) and host."
            ])
        ]),
        "required": ["url"],
        "additionalProperties": false
    ])

    public let outputSchema: JSONValue = .object([
        "type": "object",
        "properties": .object([
            "success": .object(["type": "boolean"]),
            "finalURL": .object(["type": ["string", "null"]]),
            "title": .object(["type": ["string", "null"]]),
            "error": .object(["type": ["string", "null"]])
        ]),
        "required": ["success"],
        "additionalProperties": false
    ])

    public init() {}
}

public struct EvaluateJSTool: Tool {
    public let name = "evaluate_js"
    public let description = "Evaluate JavaScript in the current page and return a JSON-compatible result."

    public let inputSchema: JSONValue = .object([
        "type": "object",
        "properties": .object([
            "script": .object([
                "type": "string",
                "description": "JavaScript code to evaluate. Must be within size limits.",
                "maxLength": .int(ToolSchemas.maxScriptSize)
            ])
        ]),
        "required": ["script"],
        "additionalProperties": false
    ])

    public let outputSchema: JSONValue = .object([
        "type": "object",
        "properties": .object([
            "result": .object(["type": ["object", "array", "string", "number", "boolean", "null"]]),
            "error": .object(["type": ["string", "null"]])
        ]),
        "required": ["result"],
        "additionalProperties": false
    ])

    public init() {}
}

public struct GetPageInfoTool: Tool {
    public let name = "get_page_info"
    public let description = "Return basic information about the current page."

    public let inputSchema: JSONValue = .object([
        "type": "object",
        "properties": .object([:]),
        "additionalProperties": false
    ])

    public let outputSchema: JSONValue = .object([
        "type": "object",
        "properties": .object([
            "url": .object(["type": ["string", "null"]]),
            "title": .object(["type": ["string", "null"]]),
            "isLoading": .object(["type": "boolean"])
        ]),
        "required": ["url", "title", "isLoading"],
        "additionalProperties": false
    ])

    public init() {}
}

public struct ClosePageTool: Tool {
    public let name = "close_page"
    public let description = "End the browser session and release its resources."

    public let inputSchema: JSONValue = .object([
        "type": "object",
        "properties": .object([:]),
        "additionalProperties": false
    ])

    public let outputSchema: JSONValue = .object([
        "type": "object",
        "properties": .object([
            "success": .object(["type": "boolean"]),
            "error": .object(["type": ["string", "null"]])
        ]),
        "required": ["success"],
        "additionalProperties": false
    ])

    public init() {}
}

public func defaultToolRegistry() -> ToolRegistry {
    var registry = ToolRegistry()
    registry.register(NavigateTool())
    registry.register(EvaluateJSTool())
    registry.register(GetPageInfoTool())
    registry.register(ClosePageTool())
    return registry
}