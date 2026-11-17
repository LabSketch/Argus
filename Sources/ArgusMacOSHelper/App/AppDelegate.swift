import Foundation
import AppKit
import ArgusCore

@MainActor
@available(macOS 26.0, *)
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var ipcServer: IPCServer?
    private let browserSession = BrowserSession()
    private var idleTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        FileHandle.standardError.write("Argus macOS Helper starting...\n".data(using: .utf8)!)

        let socketPath = defaultSocketPath()
        do {
            ipcServer = try IPCServer(socketPath: socketPath, requestHandler: RequestHandler(session: browserSession))
            try ipcServer?.start()
            FileHandle.standardError.write("IPC server listening on \(socketPath)\n".data(using: .utf8)!)
        } catch {
            FileHandle.standardError.write("Failed to start IPC server: \(error)\n".data(using: .utf8)!)
            NSApp.terminate(nil)
            return
        }

        startIdleTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        idleTimer?.invalidate()
        idleTimer = nil
        ipcServer?.stop()
        browserSession.close()
        FileHandle.standardError.write("Argus macOS Helper terminated\n".data(using: .utf8)!)
    }

    private func startIdleTimer() {
        idleTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkIdle()
            }
        }
    }

    private func checkIdle() {
        if browserSession.url == nil {
            FileHandle.standardError.write("No active session, shutting down...\n".data(using: .utf8)!)
            NSApp.terminate(nil)
        }
    }

    private func defaultSocketPath() -> String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let argusDir = appSupport.appendingPathComponent("Argus", isDirectory: true)
        try? FileManager.default.createDirectory(at: argusDir, withIntermediateDirectories: true)
        return argusDir.appendingPathComponent("ipc.sock").path
    }
}