import Foundation
import AppKit
import ArgusCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var ipcServer: IPCServer?
    private let browserSession = BrowserSession()
    private var idleTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Argus macOS Helper starting...", to: &standardError)

        let socketPath = defaultSocketPath()
        do {
            ipcServer = try IPCServer(socketPath: socketPath, requestHandler: RequestHandler(session: browserSession))
            try ipcServer?.start()
            print("IPC server listening on \(socketPath)", to: &standardError)
        } catch {
            print("Failed to start IPC server: \(error)", to: &standardError)
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
        print("Argus macOS Helper terminated", to: &standardError)
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
            print("No active session, shutting down...", to: &standardError)
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