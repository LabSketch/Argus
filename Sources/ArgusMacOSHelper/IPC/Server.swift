import Foundation
import ArgusCore

@available(macOS 26.0, *)
public final class IPCServer: @unchecked Sendable {
    private let socketPath: String
    private let requestHandler: RequestHandler
    private var serverSocket: Int32 = -1
    private var running = false
    private let queue = DispatchQueue(label: "argus.ipc.server")

    public init(socketPath: String, requestHandler: RequestHandler) {
        self.socketPath = socketPath
        self.requestHandler = requestHandler
    }

    public func start() throws {
        try? FileManager.default.removeItem(atPath: socketPath)

        serverSocket = socket(AF_UNIX, SOCK_STREAM, 0)
        guard serverSocket >= 0 else {
            throw IPCProtocolError.connectionClosed
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = Array(socketPath.utf8)
        withUnsafeMutableBytes(of: &addr.sun_path) { buffer in
            buffer.copyBytes(from: pathBytes)
        }

        let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
        let bindResult = withUnsafePointer(to: addr) { ptr in
            ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                Darwin.bind(serverSocket, sockaddrPtr, addrLen)
            }
        }

        guard bindResult == 0 else {
            close(serverSocket)
            serverSocket = -1
            throw IPCProtocolError.connectionClosed
        }

        guard listen(serverSocket, 5) == 0 else {
            close(serverSocket)
            serverSocket = -1
            throw IPCProtocolError.connectionClosed
        }

        running = true
        FileHandle.standardError.write("IPC Server started on \(socketPath)\n".data(using: .utf8)!)

        queue.async { [weak self] in
            self?.acceptLoop()
        }
    }

    public func stop() {
        running = false
        if serverSocket >= 0 {
            close(serverSocket)
            serverSocket = -1
        }
        try? FileManager.default.removeItem(atPath: socketPath)
        FileHandle.standardError.write("IPC Server stopped\n".data(using: .utf8)!)
    }

    private func acceptLoop() {
        var addr = sockaddr_un()
        var addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)

        while running {
            let clientSocket = withUnsafeMutablePointer(to: &addr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPtr in
                    Darwin.accept(serverSocket, sockaddrPtr, &addrLen)
                }
            }

            guard clientSocket >= 0 else {
                if running {
                    FileHandle.standardError.write("Accept error\n".data(using: .utf8)!)
                }
                continue
            }

            handleClient(clientSocket)
        }
    }

    private func handleClient(_ clientSocket: Int32) {
        let clientQueue = DispatchQueue(label: "argus.ipc.client.\(clientSocket)")
        var buffer = Data()

        clientQueue.async { [weak self] in
            guard let self = self else {
                close(clientSocket)
                return
            }

            var readBuffer = [UInt8](repeating: 0, count: 4096)
            while true {
                let bytesRead = Darwin.read(clientSocket, &readBuffer, readBuffer.count)
                if bytesRead <= 0 {
                    break
                }
                buffer.append(readBuffer, count: bytesRead)

                let framer = MessageFramer()
                framer.append(buffer)

                do {
                    while let messageData = try framer.nextMessage() {
                        buffer.removeFirst(messageData.count + 4)
                        Task { @MainActor in
                            do {
                                let encoder = JSONMessageEncoder()
                                let request = try encoder.decode(RPCRequest.self, from: messageData)
                                let result = try await self.requestHandler.handle(request: request)
                                let replyData = try encoder.encode(result)
                                let framedReply = FramedMessage(data: replyData).framedData
                                _ = framedReply.withUnsafeBytes { ptr in
                                    Darwin.write(clientSocket, ptr.baseAddress, framedReply.count)
                                }
                            } catch {
                                let encoder = JSONMessageEncoder()
                                let errorReply = RPCReply.failure(id: UUID(), error: .invalidRequest)
                                if let errorData = try? encoder.encode(errorReply),
                                   let framedError = FramedMessage(data: errorData).framedData as Data? {
                                    _ = framedError.withUnsafeBytes { ptr in
                                        Darwin.write(clientSocket, ptr.baseAddress, framedError.count)
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    FileHandle.standardError.write("IPC read error: \(error)\n".data(using: .utf8)!)
                    break
                }
            }
            close(clientSocket)
        }
    }
}