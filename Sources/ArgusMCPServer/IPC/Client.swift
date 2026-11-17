import Foundation
import ArgusCore

public final class IPCClient: Sendable {
    private let socketPath: String
    private let encoder: JSONMessageEncoder
    private let timeout: TimeInterval
    private let maxMessageSize = 1024 * 1024

    public init(socketPath: String = "~/Library/Application Support/Argus/ipc.sock", timeout: TimeInterval = 30) {
        self.socketPath = (socketPath as NSString).expandingTildeInPath
        self.encoder = JSONMessageEncoder()
        self.timeout = timeout
    }

    public func sendRequest(_ request: RPCRequest) async throws -> RPCReply {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let reply = try self.performRequest(request)
                    continuation.resume(returning: reply)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func performRequest(_ request: RPCRequest) throws -> RPCReply {
        let requestData = try encoder.encode(request)
        let framedData = FramedMessage(data: requestData).framedData

        var socketFD: Int32 = -1
        defer {
            if socketFD >= 0 { close(socketFD) }
        }

        socketFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard socketFD >= 0 else {
            throw IPCClientError.connectionFailed
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathCString = socketPath.utf8CString
        withUnsafeMutableBytes(of: &addr.sun_path) { buffer in
            guard buffer.count >= pathCString.count else { return }
            pathCString.withUnsafeBytes { src in
                buffer.baseAddress?.copyMemory(from: src.baseAddress!, byteCount: pathCString.count)
            }
        }

        let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
        let connectResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(socketFD, $0, addrLen)
            }
        }

        guard connectResult == 0 else {
            throw IPCClientError.connectionFailed
        }

        try framedData.withUnsafeBytes { bytes in
            var offset = 0
            let ptr = bytes.bindMemory(to: UInt8.self).baseAddress!
            while offset < framedData.count {
                let wrote = write(socketFD, ptr.advanced(by: offset), framedData.count - offset)
                guard wrote > 0 else {
                    throw IPCClientError.connectionFailed
                }
                offset += wrote
            }
        }

        var buffer = Data()
        buffer.reserveCapacity(4096)

        let startTime = Date()
        while Date().timeIntervalSince(startTime) < timeout {
            var tempBuffer = Data(count: 4096)
            let readCount = tempBuffer.withUnsafeMutableBytes { ptr in
                read(socketFD, ptr.baseAddress!, ptr.count)
            }

            guard readCount > 0 else {
                if readCount == 0 { break }
                throw IPCClientError.connectionFailed
            }

            buffer.append(tempBuffer.prefix(readCount))

            while let messageData = try parseSingle(from: &buffer) {
                let reply = try encoder.decode(RPCReply.self, from: messageData)
                return reply
            }
        }

        throw IPCClientError.timeout
    }

    private func parseSingle(from buffer: inout Data) throws -> Data? {
        guard buffer.count >= 4 else { return nil }
        let length = buffer.prefix(4).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        guard length <= maxMessageSize else {
            throw IPCProtocolError.messageTooLarge(maxSize: maxMessageSize, actualSize: Int(length))
        }
        guard buffer.count >= 4 + Int(length) else { return nil }
        let messageData = buffer[4..<4+Int(length)]
        buffer.removeFirst(4 + Int(length))
        return Data(messageData)
    }
}

public enum IPCClientError: Error, Sendable {
    case connectionFailed
    case timeout
    case encodingFailed(Error)
    case decodingFailed(Error)
    case invalidResponse
}