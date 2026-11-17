import Foundation

public struct RPCRequest: Codable, Sendable {
    public let id: UUID
    public let method: String
    public let params: JSONValue?

    public init(id: UUID = UUID(), method: String, params: JSONValue? = nil) {
        self.id = id
        self.method = method
        self.params = params
    }
}

public struct RPCReply: Codable, Sendable {
    public let id: UUID
    public let result: JSONValue?
    public let error: RPCError?

    public init(id: UUID, result: JSONValue? = nil, error: RPCError? = nil) {
        self.id = id
        self.result = result
        self.error = error
    }

    public static func success(id: UUID, result: JSONValue? = nil) -> RPCReply {
        RPCReply(id: id, result: result, error: nil)
    }

    public static func failure(id: UUID, error: RPCError) -> RPCReply {
        RPCReply(id: id, result: nil, error: error)
    }
}

public struct RPCError: Codable, Sendable, Error {
    public let code: Int
    public let message: String
    public let data: JSONValue?

    public init(code: Int, message: String, data: JSONValue? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }

    public static let parseError = RPCError(code: -32700, message: "Parse error")
    public static let invalidRequest = RPCError(code: -32600, message: "Invalid request")
    public static let methodNotFound = RPCError(code: -32601, message: "Method not found")
    public static let invalidParams = RPCError(code: -32602, message: "Invalid params")
    public static let internalError = RPCError(code: -32603, message: "Internal error")
    public static let serverError = RPCError(code: -32000, message: "Server error")

    public static func applicationError(code: Int, message: String, data: JSONValue? = nil) -> RPCError {
        RPCError(code: code, message: message, data: data)
    }
}

public enum JSONValue: Codable, Sendable, Equatable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unable to decode JSONValue"
            ))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }

    public var asBool: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    public var asInt: Int? {
        if case .int(let value) = self { return value }
        return nil
    }

    public var asDouble: Double? {
        if case .double(let value) = self { return value }
        if case .int(let value) = self { return Double(value) }
        return nil
    }

    public var asString: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    public var asArray: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    public var asObject: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }
}

extension JSONValue: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension JSONValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension JSONValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension JSONValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .double(value)
    }
}

extension JSONValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension JSONValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }
}

extension JSONValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}

public struct NavigationResult: Codable, Sendable, Equatable {
    public let success: Bool
    public let finalURL: String?
    public let title: String?
    public let error: String?

    public init(success: Bool, finalURL: String? = nil, title: String? = nil, error: String? = nil) {
        self.success = success
        self.finalURL = finalURL
        self.title = title
        self.error = error
    }
}

public struct PageInfo: Codable, Sendable, Equatable {
    public let url: String?
    public let title: String?
    public let isLoading: Bool

    public init(url: String?, title: String?, isLoading: Bool) {
        self.url = url
        self.title = title
        self.isLoading = isLoading
    }
}

public struct EvaluateJSResult: Codable, Sendable, Equatable {
    public let result: JSONValue?
    public let error: String?

    public init(result: JSONValue? = nil, error: String? = nil) {
        self.result = result
        self.error = error
    }
}