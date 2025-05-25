.PHONY: build test test-coverage lint lint-fix format format-check security deps clean ci help

# Build configuration
BINARY_NAME=agent
BUILD_DIR=build
COVERAGE_FILE=coverage.out
COVERAGE_HTML=coverage.html

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the main binary
	@mkdir -p $(BUILD_DIR)
	go build -o $(BUILD_DIR)/$(BINARY_NAME) .

test: ## Run tests with coverage
	go test -race -coverprofile=$(COVERAGE_FILE) -covermode=atomic ./...
	go tool cover -html=$(COVERAGE_FILE) -o $(COVERAGE_HTML)

test-coverage: ## Run tests and display coverage in terminal
	go test -race -coverprofile=$(COVERAGE_FILE) -covermode=atomic ./...
	go tool cover -func=$(COVERAGE_FILE)

lint: ## Run golangci-lint
	golangci-lint run --config=.golangci.yml

lint-fix: ## Run golangci-lint with auto-fix
	golangci-lint run --config=.golangci.yml --fix

format: ## Format code with gofmt and goimports
	gofmt -s -w .
	goimports -w .

format-check: ## Check if code is properly formatted
	@if [ -n "$$(gofmt -s -l .)" ]; then \
		echo "The following files are not formatted:"; \
		gofmt -s -l .; \
		echo "Please run 'make format' to format your code."; \
		exit 1; \
	fi
	@if command -v goimports >/dev/null 2>&1; then \
		if [ -n "$$(goimports -l .)" ]; then \
			echo "The following files have import issues:"; \
			goimports -l .; \
			echo "Please run 'make format' to fix your imports."; \
			exit 1; \
		fi; \
	else \
		go install golang.org/x/tools/cmd/goimports@latest; \
		if [ -n "$$(goimports -l .)" ]; then \
			echo "The following files have import issues:"; \
			goimports -l .; \
			echo "Please run 'make format' to fix your imports."; \
			exit 1; \
		fi; \
	fi

security: ## Run security checks with gosec
	@if ! command -v gosec >/dev/null 2>&1; then \
		echo "Installing gosec..."; \
		go install github.com/securego/gosec/v2/cmd/gosec@latest; \
	fi
	gosec ./...

deps: ## Download and verify dependencies
	go mod download
	go mod verify
	go mod tidy

clean: ## Clean build artifacts and coverage files
	rm -rf $(BUILD_DIR)/
	rm -f $(COVERAGE_FILE) $(COVERAGE_HTML)

ci: deps format-check lint test security build ## Run all CI checks locally 
