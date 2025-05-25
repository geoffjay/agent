#!/bin/bash

# CI Development Script
# This script runs the same checks as the GitHub Actions CI pipeline locally

set -e

echo "🚀 Running CI checks locally..."
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print step headers
print_step() {
    echo -e "${YELLOW}📋 $1${NC}"
    echo "----------------------------------------"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo
}

# Function to print error and exit
print_error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Check if we're in a Go project
if [ ! -f "go.mod" ]; then
    print_error "go.mod not found. Are you in the root of a Go project?"
fi

# Step 1: Dependencies
print_step "Downloading and verifying dependencies"
go mod download || print_error "Failed to download dependencies"
go mod verify || print_error "Failed to verify dependencies"
print_success "Dependencies verified"

# Step 2: Formatting check
print_step "Checking code formatting"
if [ -n "$(gofmt -s -l .)" ]; then
    echo "The following files are not formatted:"
    gofmt -s -l .
    print_error "Code formatting check failed. Run 'make format' to fix."
fi

# Check if goimports is available, install if not
if ! command -v goimports >/dev/null 2>&1; then
    echo "Installing goimports..."
    go install golang.org/x/tools/cmd/goimports@latest
fi

if [ -n "$(goimports -l .)" ]; then
    echo "The following files have import issues:"
    goimports -l .
    print_error "Import formatting check failed. Run 'make format' to fix."
fi
print_success "Code formatting is correct"

# Step 3: Linting
print_step "Running golangci-lint"
if ! command -v golangci-lint >/dev/null 2>&1; then
    print_error "golangci-lint not found. Please install it: https://golangci-lint.run/usage/install/"
fi
golangci-lint run --config=.golangci.yml || print_error "Linting failed"
print_success "Linting passed"

# Step 4: Security check
print_step "Running security checks"
if ! command -v gosec >/dev/null 2>&1; then
    echo "Installing gosec..."
    go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest
fi
gosec ./... || print_error "Security checks failed"
print_success "Security checks passed"

# Step 5: Tests
print_step "Running tests with coverage"
go test -race -coverprofile=coverage.out -covermode=atomic ./... || print_error "Tests failed"
go tool cover -func=coverage.out
print_success "Tests passed"

# Step 6: Build
print_step "Building application"
mkdir -p build
go build -v ./... || print_error "Build failed"
go build -o build/agent . || print_error "Binary build failed"
print_success "Build completed"

echo -e "${GREEN}🎉 All CI checks passed!${NC}"
echo "Your code is ready for commit and push." 
