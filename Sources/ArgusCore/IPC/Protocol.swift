import Foundation

public enum IPCProtocolError: Error, Sendable {
    case messageTooLarge(maxSize: Int, actualSize: Int)
    case invalidMessageFormat(String)
    case encodingFailed(Error)
    case decodingFailed(Error)
    case connectionClosed
    case timeout
}

public protocol IPCMessageEncoder: Sendable {
    func encode<T: Encodable>(_ value: T) throws -> Data
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

public struct JSONMessageEncoder: IPCMessageEncoder {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init() {
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    public func encode<T: Encodable>(_ value: T) throws -> Data {
        do {
            return try encoder.encode(value)
        } catch {
            throw IPCProtocolError.encodingFailed(error)
        }
    }

    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw IPCProtocolError.decodingFailed(error)
        }
    }
}

public struct FramedMessage {
    public let length: UInt32
    public let data: Data

    public init(data: Data) {
        self.length = UInt32(data.count)
        self.data = data
    }

    public var framedData: Data {
        var result = Data()
        result.reserveCapacity(4 + data.count)
        withUnsafeBytes(of: length.bigEndian) { result.append(contentsOf: $0) }
        result.append(data)
        return result
    }

    public static func parse(from buffer: inout Data) -> FramedMessage? {
        guard buffer.count >= 4 else { return nil }
        let lengthBytes = buffer.prefix(4)
        var length: UInt32 = 0
        withUnsafeMutableBytes(of: &length) { ptr in
            lengthBytes.copyBytes(to: ptr)
        }
        length = length.bigEndian
        guard buffer.count >= 4 + Int(length) else { return nil }
        let messageData = buffer[4..<4+Int(length)]
        buffer.removeFirst(4 + Int(length))
        return FramedMessage(data: Data(messageData))
    }
}

public final class MessageFramer: @unchecked Sendable {
    private var buffer = Data()
    private let maxMessageSize: Int

    public init(maxMessageSize: Int = 1024 * 1024) {
        self.maxMessageSize = maxMessageSize
    }

    public func append(_ data: Data) {
        buffer.append(data)
    }

    public func nextMessage() throws -> Data? {
        while true {
            guard buffer.count >= 4 else { return nil }
            let lengthBytes = buffer.prefix(4)
            var length: UInt32 = 0
            withUnsafeMutableBytes(of: &length) { ptr in
                lengthBytes.copyBytes(to: ptr)
            }
            length = length.bigEndian
            guard length <= maxMessageSize else {
                throw IPCProtocolError.messageTooLarge(maxSize: maxMessageSize, actualSize: Int(length))
            }
            guard buffer.count >= 4 + Int(length) else { return nil }
            let messageData = buffer[4..<4+Int(length)]
            buffer.removeFirst(4 + Int(length))
            return Data(messageData)
        }
    }

    public func clear() {
        buffer.removeAll()
    }
}