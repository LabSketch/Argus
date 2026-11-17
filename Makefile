.PHONY: help build test clean run-mcp-server run-helper package xcodeproj

# Default target
help:
	@echo "Argus - Build and development commands"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  build             Build all targets (SPM + Xcode if available)"
	@echo "  build-spm         Build Swift Package Manager targets only"
	@echo "  build-helper      Build macOS Helper app (requires Xcode project)"
	@echo "  test              Run all tests (SPM + Xcode if available)"
	@echo "  test-spm          Run Swift Package Manager tests only"
	@echo "  test-helper       Run macOS Helper tests (requires Xcode project)"
	@echo "  run-mcp-server    Run the MCP server (requires Helper running)"
	@echo "  run-helper        Launch the macOS Helper app"
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

# Xcode targets (require Argus.xcodeproj to exist)
XCODEPROJ := Argus.xcodeproj
HELPER_SCHEME := ArgusMacOSHelper
HELPER_APP := build/Build/Products/Debug/ArgusMacOSHelper.app

build-helper: $(XCODEPROJ)
	xcodebuild -project $(XCODEPROJ) -scheme $(HELPER_SCHEME) build

test-helper: $(XCODEPROJ)
	xcodebuild test -project $(XCODEPROJ) -scheme $(HELPER_SCHEME)

run-helper: build-helper
	open $(HELPER_APP)

# Combined targets
build: build-spm
	@if [ -f $(XCODEPROJ) ]; then \
		$(MAKE) build-helper; \
	else \
		echo "Note: Xcode project not found, skipping Helper build"; \
		echo "Run 'make xcodeproj' to generate it (requires xcodegen)"; \
	fi

test: test-spm
	@if [ -f $(XCODEPROJ) ]; then \
		$(MAKE) test-helper; \
	else \
		echo "Note: Xcode project not found, skipping Helper tests"; \
	fi

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