import Testing
import Foundation
@testable import ArgusCore

@Suite("ToolRegistry Tests")
struct ToolRegistryTests {
    @Test("Register and retrieve tools")
    func registerAndRetrieve() {
        var registry = ToolRegistry()
        let tool = NavigateTool()
        
        registry.register(tool)
        
        #expect(registry.toolNames == ["navigate"])
        #expect(registry.tool(named: "navigate")?.name == "navigate")
        #expect(registry.tool(named: "nonexistent") == nil)
    }

    @Test("All tools")
    func allTools() {
        var registry = ToolRegistry()
        registry.register(NavigateTool())
        registry.register(EvaluateJSTool())
        
        #expect(registry.allTools.count == 2)
        #expect(registry.toolNames.sorted() == ["evaluate_js", "navigate"])
    }
}

@Suite("ToolSchemas Tests")
struct ToolSchemasTests {
    @Test("Default registry has all tools")
    func defaultRegistry() {
        let registry = defaultToolRegistry()
        #expect(registry.toolNames.sorted() == ["close_page", "evaluate_js", "get_page_info", "navigate"])
    }

    @Test("URL validation - allowed scheme")
    func allowedScheme() {
        let result = ToolSchemas.validateURL("https://example.com")
        #expect(result != nil)
        #expect(result?.0.absoluteString == "https://example.com")
    }

    @Test("URL validation - disallowed scheme")
    func disallowedScheme() {
        let result = ToolSchemas.validateURL("http://example.com")
        #expect(result == nil)
    }

    @Test("URL validation - file scheme")
    func fileScheme() {
        let result = ToolSchemas.validateURL("file:///etc/passwd")
        #expect(result == nil)
    }

    @Test("URL validation - host allowlist")
    func hostAllowlist() {
        ToolSchemas.allowedHosts = ["example.com", "test.com"]
        defer { ToolSchemas.allowedHosts = [] }
        
        let allowed = ToolSchemas.validateURL("https://example.com")
        #expect(allowed != nil)
        
        let disallowed = ToolSchemas.validateURL("https://other.com")
        #expect(disallowed == nil)
    }

    @Test("Script size validation")
    func scriptSize() {
        let smallScript = "console.log('hello')"
        #expect(ToolSchemas.validateScript(smallScript) == true)
        
        let largeScript = String(repeating: "a", count: ToolSchemas.maxScriptSize + 1)
        #expect(ToolSchemas.validateScript(largeScript) == false)
    }
}

@Suite("NavigateTool Tests")
struct NavigateToolTests {
    let tool = NavigateTool()

    @Test("Tool properties")
    func properties() {
        #expect(tool.name == "navigate")
        #expect(tool.description.contains("Load a permitted URL"))
    }

    @Test("Input schema structure")
    func inputSchema() {
        let schema = tool.inputSchema.asObject
        #expect(schema?["type"]?.asString == "object")
        #expect(schema?["properties"]?.asObject?["url"] != nil)
        #expect(schema?["required"]?.asArray?.contains(.string("url")) == true)
    }

    @Test("Output schema structure")
    func outputSchema() {
        let schema = tool.outputSchema.asObject
        #expect(schema?["type"]?.asString == "object")
        #expect(schema?["properties"]?.asObject?["success"] != nil)
        #expect(schema?["properties"]?.asObject?["finalURL"] != nil)
    }
}

@Suite("EvaluateJSTool Tests")
struct EvaluateJSToolTests {
    let tool = EvaluateJSTool()

    @Test("Tool properties")
    func properties() {
        #expect(tool.name == "evaluate_js")
        #expect(tool.description.contains("Evaluate JavaScript"))
    }

    @Test("Input schema has maxLength")
    func inputSchema() {
        let schema = tool.inputSchema.asObject
        let scriptProp = schema?["properties"]?.asObject?["script"]?.asObject
        #expect(scriptProp?["maxLength"]?.asInt == ToolSchemas.maxScriptSize)
    }
}

@Suite("GetPageInfoTool Tests")
struct GetPageInfoToolTests {
    let tool = GetPageInfoTool()

    @Test("Tool properties")
    func properties() {
        #expect(tool.name == "get_page_info")
        #expect(tool.description.contains("basic information"))
    }

    @Test("Empty input schema")
    func inputSchema() {
        let schema = tool.inputSchema.asObject
        #expect(schema?["type"]?.asString == "object")
        #expect(schema?["properties"]?.asObject?.isEmpty == true)
    }
}

@Suite("ClosePageTool Tests")
struct ClosePageToolTests {
    let tool = ClosePageTool()

    @Test("Tool properties")
    func properties() {
        #expect(tool.name == "close_page")
        #expect(tool.description.contains("End the browser session"))
    }
}