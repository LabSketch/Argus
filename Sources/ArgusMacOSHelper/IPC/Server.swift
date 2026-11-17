import Foundation
import ArgusCore

public final class IPCServer {
    private let socketPath: String
    private let requestHandler: RequestHandler
    private var listener: CFSocket?
    private var runLoopSource: CFRunLoopSource?

    public init(socketPath: String, requestHandler: RequestHandler) {
        self.socketPath = socketPath
        self.requestHandler = requestHandler
    }

    public func start() throws {
        try FileManager.default.removeItemIfExists(atPath: socketPath)

        var context = CFSocketContext(version: 0, info: Unmanaged.passRetained(self).toOpaque(), retain: nil, release: { ptr in
            Unmanaged<IPCServer>.fromOpaque(ptr).release()
        }, copyDescription: nil)

        let callback: CFSocketCallBack = { socket, callbackType, address, data, info in
            guard let info = info else { return }
            let server = Unmanaged<IPCServer>.fromOpaque(info).takeUnretainedValue()
            
            if callbackType == CFSocketAcceptCallBack {
                server.handleAccept(socket: socket, nativeHandle: data)
            }
        }

        listener = CFSocketCreate(kCFAllocatorDefault, PF_UNIX, SOCK_STREAM, 0, CFSocketAcceptCallBack, callback, &context)

        guard let listener = listener else {
            throw IPCProtocolError.connectionClosed
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        let pathBytes = socketPath.utf8CString
        _ = withUnsafeMutableBytes(of: &addr.sun_path) { buffer in
            buffer.copyBytes(from: pathBytes)
        }

        let addrData = Data(bytes: &addr, count: MemoryLayout<sockaddr_un>.size)
        let bindResult = CFSocketSetAddress(listener, addrData as CFData)

        if bindResult != .success {
            CFSocketInvalidate(listener)
            throw IPCProtocolError.connectionClosed
        }

        runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, listener, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource!, .commonModes)

        print("IPC Server started on \(socketPath)", to: &standardError)
    }

    public func stop() {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        if let listener = listener {
            CFSocketInvalidate(listener)
            self.listener = nil
        }
        try? FileManager.default.removeItemIfExists(atPath: socketPath)
        print("IPC Server stopped", to: &standardError)
    }

    private func handleAccept(socket: CFSocket, nativeHandle: CFData?) {
        guard let nativeHandle = nativeHandle,
              let clientSocket = CFSocketCreateWithNative(kCFAllocatorDefault, CFSocketGetNative(socket), 0, nil, nil) else {
            return
        }

        let clientHandler = ClientConnection(socket: clientSocket, handler: requestHandler)
        clientHandler.start()
    }
}

private final class ClientConnection {
    private let socket: CFSocket
    private let handler: RequestHandler
    private let framer = MessageFramer()
    private let encoder = JSONMessageEncoder()
    private var runLoopSource: CFRunLoopSource?

    init(socket: CFSocket, handler: RequestHandler) {
        self.socket = socket
        self.handler = handler
    }

    func start() {
        var context = CFSocketContext(version: 0, info: Unmanaged.passRetained(self).toOpaque(), retain: nil, release: { ptr in
            Unmanaged<ClientConnection>.fromOpaque(ptr).release()
        }, copyDescription: nil)

        let callback: CFSocketCallBack = { socket, callbackType, address, data, info in
            guard let info = info else { return }
            let connection = Unmanaged<ClientConnection>.fromOpaque(info).takeUnretainedValue()
            
            if callbackType == CFSocketReadCallBack, let data = data as? Data {
                connection.handleRead(data: data)
            }
        }

        CFSocketSetSocketFlags(socket, CFSocketFlags(kCFSocketReadCallBack))
        CFSocketSetCallback(socket, callback, &context)

        runLoopSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, socket, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource!, .commonModes)
    }

    private func handleRead(data: Data) {
        framer.append(data)

        do {
            while let messageData = try framer.nextMessage() {
                do {
                    let request = try encoder.decode(RPCRequest.self, from: messageData)
                    let reply = try handler.handle(request: request)
                    let replyData = try encoder.encode(reply)
                    let framedReply = FramedMessage(data: replyData).framedData
                    CFSocketSendData(socket, 0, framedReply as CFData, 5.0)
                } catch {
                    let errorReply = RPCReply.failure(id: UUID(), error: .invalidRequest)
                    if let errorData = try? encoder.encode(errorReply),
                       let framedError = FramedMessage(data: errorData).framedData as CFData? {
                        CFSocketSendData(socket, 0, framedError, 5.0)
                    }
                }
            }
        } catch {
            print("IPC read error: \(error)", to: &standardError)
            close()
        }
    }

    private func close() {
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }
        CFSocketInvalidate(socket)
    }
}