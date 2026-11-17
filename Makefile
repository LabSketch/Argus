.PHONY: help build test clean run-mcp-server run-helper package xcodeproj build-helper-spm package-helper build-mcp-server package-mcp-server

# Default target
help:
	@echo "Argus - Build and development commands"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  build             Build all targets (SPM + Helper app + MCP binary)"
	@echo "  build-spm         Build Swift Package Manager targets only"
	@echo "  build-helper      Build macOS Helper app via SwiftPM + package as .app"
	@echo "  build-mcp-server  Build MCP Server binary (copied to build/bin/)"
	@echo "  test              Run all tests (SPM)"
	@echo "  test-spm          Run Swift Package Manager tests only"
	@echo "  run-mcp-server    Run the MCP server (requires Helper running)"
	@echo "  run-helper        Build and launch the macOS Helper app"
	@echo "  clean             Clean build artifacts"
	@echo "  package           Create release package (not implemented)"
	@echo "  xcodeproj         Generate Xcode project with xcodegen (if available)"
	@echo "  help              Show this help"

# Swift Package Manager targets
build-spm:
	swift build

test-spm:
	swift test

run-mcp-server:
	swift run ArgusMCPServer

# Helper app via SwiftPM + manual .app bundle creation
HELPER_EXECUTABLE := .build/debug/ArgusMacOSHelper
HELPER_APP := build/ArgusMacOSHelper.app
HELPER_CONTENTS := $(HELPER_APP)/Contents
HELPER_MACOS := $(HELPER_CONTENTS)/MacOS
HELPER_RESOURCES := $(HELPER_CONTENTS)/Resources
INFOPLIST := Sources/ArgusMacOSHelper/Resources/Info.plist

build-helper-spm: build-spm
	@mkdir -p $(HELPER_MACOS)
	@mkdir -p $(HELPER_RESOURCES)
	@cp $(HELPER_EXECUTABLE) $(HELPER_MACOS)/ArgusMacOSHelper
	@cp $(INFOPLIST) $(HELPER_CONTENTS)/Info.plist
	@echo "Helper app created at $(HELPER_APP)"

package-helper: build-helper-spm
	@echo "Helper app packaged at $(HELPER_APP)"

build-helper: build-helper-spm

run-helper: build-helper-spm
	open $(HELPER_APP)

# MCP Server binary
MCP_EXECUTABLE := .build/debug/ArgusMCPServer
MCP_BIN_DIR := build/bin

build-mcp-server: build-spm
	@mkdir -p $(MCP_BIN_DIR)
	@cp $(MCP_EXECUTABLE) $(MCP_BIN_DIR)/argus-mcp-server
	@chmod +x $(MCP_BIN_DIR)/argus-mcp-server
	@echo "MCP Server binary created at $(MCP_BIN_DIR)/argus-mcp-server"

package-mcp-server: build-mcp-server
	@echo "MCP Server binary packaged at $(MCP_BIN_DIR)/argus-mcp-server"

# Combined targets
build: build-spm build-helper-spm build-mcp-server

test: test-spm

# Clean
clean:
	swift package clean
	rm -rf build
	rm -rf .build

# Xcode project generation (optional, requires xcodegen)
xcodeproj:
	@if command -v xcodegen >/dev/null 2>&1; then \
		xcodegen generate; \
	else \
		echo "xcodegen not installed. Install with: brew install xcodegen"; \
		echo "Or create the Xcode project manually (see README.md)"; \
		exit 1; \
	fi

# Package (placeholder for future release packaging)
package: build
	@echo "Packaging not yet implemented"
	@exit 1