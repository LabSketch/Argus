import Testing
import Foundation
@testable import ArgusCore

@Suite("RPCRequest Tests")
struct RPCRequestTests {
    @Test("Encoding and decoding round-trip")
    func roundTrip() throws {
        let request = RPCRequest(method: "test_method", params: .object(["key": .string("value")]))
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(RPCRequest.self, from: data)
        
        #expect(decoded.id == request.id)
        #expect(decoded.method == request.method)
        #expect(decoded.params?.asObject?["key"]?.asString == "value")
    }

    @Test("Default ID generation")
    func defaultID() {
        let request = RPCRequest(method: "test")
        #expect(request.id != UUID())
    }

    @Test("Nil params")
    func nilParams() throws {
        let request = RPCRequest(method: "test")
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(RPCRequest.self, from: data)
        #expect(decoded.params == nil)
    }
}

@Suite("RPCReply Tests")
struct RPCReplyTests {
    @Test("Success reply")
    func success() throws {
        let reply = RPCReply.success(id: UUID(), result: .string("ok"))
        let data = try JSONEncoder().encode(reply)
        let decoded = try JSONDecoder().decode(RPCReply.self, from: data)
        
        #expect(decoded.id == reply.id)
        #expect(decoded.result?.asString == "ok")
        #expect(decoded.error == nil)
    }

    @Test("Failure reply")
    func failure() throws {
        let reply = RPCReply.failure(id: UUID(), error: .invalidParams)
        let data = try JSONEncoder().encode(reply)
        let decoded = try JSONDecoder().decode(RPCReply.self, from: data)
        
        #expect(decoded.id == reply.id)
        #expect(decoded.result == nil)
        #expect(decoded.error?.code == RPCError.invalidParams.code)
        #expect(decoded.error?.message == RPCError.invalidParams.message)
    }
}

@Suite("RPCError Tests")
struct RPCErrorTests {
    @Test("Standard error codes")
    func standardCodes() {
        #expect(RPCError.parseError.code == -32700)
        #expect(RPCError.invalidRequest.code == -32600)
        #expect(RPCError.methodNotFound.code == -32601)
        #expect(RPCError.invalidParams.code == -32602)
        #expect(RPCError.internalError.code == -32603)
        #expect(RPCError.serverError.code == -32000)
    }

    @Test("Application error creation")
    func applicationError() {
        let error = RPCError.applicationError(code: -32001, message: "Custom error", data: .string("extra"))
        #expect(error.code == -32001)
        #expect(error.message == "Custom error")
        #expect(error.data?.asString == "extra")
    }
}

@Suite("JSONValue Tests")
struct JSONValueTests {
    @Test("Literal initialization")
    func literals() {
        let null: JSONValue = nil
        let bool: JSONValue = true
        let int: JSONValue = 42
        let double: JSONValue = 3.14
        let string: JSONValue = "hello"
        let array: JSONValue = [1, 2, 3]
        let object: JSONValue = ["key": "value"]

        #expect(null == .null)
        #expect(bool.asBool == true)
        #expect(int.asInt == 42)
        #expect(double.asDouble == 3.14)
        #expect(string.asString == "hello")
        #expect(array.asArray?.count == 3)
        #expect(object.asObject?["key"]?.asString == "value")
    }

    @Test("Encoding and decoding")
    func encoding() throws {
        let value: JSONValue = .object([
            "string": "hello",
            "number": 42,
            "bool": true,
            "null": nil,
            "array": [1, 2, 3],
            "nested": ["key": "value"]
        ])

        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(JSONValue.self, from: data)

        #expect(decoded.asObject?["string"]?.asString == "hello")
        #expect(decoded.asObject?["number"]?.asInt == 42)
        #expect(decoded.asObject?["bool"]?.asBool == true)
        #expect(decoded.asObject?["null"] == .null)
        #expect(decoded.asObject?["array"]?.asArray?.count == 3)
        #expect(decoded.asObject?["nested"]?.asObject?["key"]?.asString == "value")
    }

    @Test("Equality")
    func equality() {
        #expect(JSONValue.int(42) == JSONValue.int(42))
        #expect(JSONValue.string("hello") == JSONValue.string("hello"))
        #expect(JSONValue.int(42) != JSONValue.int(43))
    }
}

@Suite("NavigationResult Tests")
struct NavigationResultTests {
    @Test("Success result")
    func success() throws {
        let result = NavigationResult(success: true, finalURL: "https://example.com", title: "Example", error: nil)
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(NavigationResult.self, from: data)
        
        #expect(decoded.success == true)
        #expect(decoded.finalURL == "https://example.com")
        #expect(decoded.title == "Example")
        #expect(decoded.error == nil)
    }

    @Test("Error result")
    func error() throws {
        let result = NavigationResult(success: false, error: "Navigation failed")
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(NavigationResult.self, from: data)
        
        #expect(decoded.success == false)
        #expect(decoded.error == "Navigation failed")
    }
}

@Suite("PageInfo Tests")
struct PageInfoTests {
    @Test("Full info")
    func fullInfo() throws {
        let info = PageInfo(url: "https://example.com", title: "Example", isLoading: false)
        let data = try JSONEncoder().encode(info)
        let decoded = try JSONDecoder().decode(PageInfo.self, from: data)
        
        #expect(decoded.url == "https://example.com")
        #expect(decoded.title == "Example")
        #expect(decoded.isLoading == false)
    }
}

@Suite("EvaluateJSResult Tests")
struct EvaluateJSResultTests {
    @Test("Success result")
    func success() throws {
        let result = EvaluateJSResult(result: .int(42), error: nil)
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(EvaluateJSResult.self, from: data)
        
        #expect(decoded.result?.asInt == 42)
        #expect(decoded.error == nil)
    }
}