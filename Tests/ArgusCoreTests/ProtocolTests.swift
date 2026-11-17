import Testing
import Foundation
@testable import ArgusCore

@Suite("JSONMessageEncoder Tests")
struct JSONMessageEncoderTests {
    let encoder = JSONMessageEncoder()

    @Test("Encode and decode request")
    func requestRoundTrip() throws {
        let request = RPCRequest(method: "test", params: .object(["key": .string("value")]))
        let data = try encoder.encode(request)
        let decoded = try encoder.decode(RPCRequest.self, from: data)
        
        #expect(decoded.id == request.id)
        #expect(decoded.method == request.method)
    }

    @Test("Encode and decode reply")
    func replyRoundTrip() throws {
        let reply = RPCReply.success(id: UUID(), result: .string("result"))
        let data = try encoder.encode(reply)
        let decoded = try encoder.decode(RPCReply.self, from: data)
        
        #expect(decoded.id == reply.id)
        #expect(decoded.result?.asString == "result")
    }

    @Test("Encode error")
    func errorEncoding() throws {
        let error = RPCError.invalidParams
        let data = try encoder.encode(error)
        let decoded = try encoder.decode(RPCError.self, from: data)
        
        #expect(decoded.code == error.code)
        #expect(decoded.message == error.message)
    }
}

@Suite("FramedMessage Tests")
struct FramedMessageTests {
    @Test("Framing and parsing")
    func framing() throws {
        let originalData = Data("hello world".utf8)
        let framed = FramedMessage(data: originalData)
        let framedData = framed.framedData
        
        var buffer = framedData
        let parsed = FramedMessage.parse(from: &buffer)
        
        #expect(parsed != nil)
        #expect(parsed?.data == originalData)
        #expect(buffer.isEmpty)
    }

    @Test("Multiple messages in buffer")
    func multipleMessages() throws {
        let msg1 = FramedMessage(data: Data("first".utf8)).framedData
        let msg2 = FramedMessage(data: Data("second".utf8)).framedData
        var buffer = msg1 + msg2
        
        let parsed1 = FramedMessage.parse(from: &buffer)
        #expect(parsed1?.data == Data("first".utf8))
        
        let parsed2 = FramedMessage.parse(from: &buffer)
        #expect(parsed2?.data == Data("second".utf8))
        
        #expect(buffer.isEmpty)
    }

    @Test("Incomplete message returns nil")
    func incompleteMessage() {
        let framed = FramedMessage(data: Data("hello".utf8)).framedData
        var buffer = framed.dropLast(2)
        
        let parsed = FramedMessage.parse(from: &buffer)
        #expect(parsed == nil)
    }
}

@Suite("MessageFramer Tests")
struct MessageFramerTests {
    @Test("Basic framing")
    func basic() throws {
        let framer = MessageFramer()
        let data = FramedMessage(data: Data("test".utf8)).framedData
        framer.append(data)
        
        let message = try framer.nextMessage()
        #expect(message == Data("test".utf8))
    }

    @Test("Chunked input")
    func chunked() throws {
        let framer = MessageFramer()
        let framed = FramedMessage(data: Data("test".utf8)).framedData
        
        framer.append(framed.prefix(2))
        #expect(try framer.nextMessage() == nil)
        
        framer.append(framed.dropFirst(2))
        let message = try framer.nextMessage()
        #expect(message == Data("test".utf8))
    }

    @Test("Multiple messages")
    func multiple() throws {
        let framer = MessageFramer()
        let msg1 = FramedMessage(data: Data("first".utf8)).framedData
        let msg2 = FramedMessage(data: Data("second".utf8)).framedData
        
        framer.append(msg1 + msg2)
        
        let m1 = try framer.nextMessage()
        #expect(m1 == Data("first".utf8))
        
        let m2 = try framer.nextMessage()
        #expect(m2 == Data("second".utf8))
        
        #expect(try framer.nextMessage() == nil)
    }

    @Test("Message too large throws")
    func tooLarge() throws {
        let framer = MessageFramer(maxMessageSize: 10)
        let largeData = Data(repeating: 0x41, count: 20)
        let framed = FramedMessage(data: largeData).framedData
        
        framer.append(framed)
        
        #expect(throws: IPCProtocolError.self) {
            try framer.nextMessage()
        }
    }
}