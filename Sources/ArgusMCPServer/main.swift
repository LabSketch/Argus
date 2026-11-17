import Foundation
import ArgusCore

let ipcClient = IPCClient()
let toolRegistry = MCPToolRegistry(ipcClient: ipcClient)
let server = MCPServer(toolRegistry: toolRegistry)

await server.run()