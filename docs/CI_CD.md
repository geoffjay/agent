# CI/CD Documentation

This document describes the continuous integration and continuous deployment setup for this Go project.

## GitHub Actions Workflow

The project uses GitHub Actions for CI/CD with the following checks:

### Workflow Jobs

1. **Test** - Runs unit tests with race detection and generates coverage reports
2. **Lint** - Runs `golangci-lint` with comprehensive linting rules
3. **Format** - Checks code formatting with `gofmt` and import organization with `goimports`
4. **Build** - Compiles the application and uploads artifacts
5. **Security** - Runs `gosec` security analysis

### Triggers

- **Push** to `main` or `master` branches
- **Pull Request** to `main` or `master` branches

### Configuration Files

- `.github/workflows/ci.yml` - Main CI workflow
- `.golangci.yml` - Linter configuration
- `go.mod` - Go module dependencies

## Local Development

### Prerequisites

Install the required tools:

```bash
# golangci-lint (for linting)
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# goimports (for import formatting)
go install golang.org/x/tools/cmd/goimports@latest

# gosec (for security analysis)
go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest
```

### Running CI Checks Locally

#### Option 1: Use Make (Recommended)

```bash
# Run all CI checks
make ci

# Individual checks
make test           # Run tests with coverage
make lint           # Run linting
make format-check   # Check formatting
make security       # Run security checks
make build          # Build the application

# Development helpers
make format         # Format code
make lint-fix       # Auto-fix linting issues
make clean          # Clean build artifacts
make help           # Show all available targets
```

#### Option 2: Use Task

```bash
# Run all CI checks
task ci

# Individual checks
task test           # Run tests with coverage
task lint           # Run linting
task format:check   # Check formatting
task security       # Run security checks
task build          # Build the application

# Development helpers
task format         # Format code
task lint:fix       # Auto-fix linting issues
task clean          # Clean build artifacts
```

#### Option 3: Use the CI Script

```bash
# Run all checks in sequence (like CI)
./scripts/ci.sh
```

#### Option 4: Manual Commands

```bash
# Download dependencies
go mod download
go mod verify

# Format check
gofmt -s -l .
goimports -l .

# Linting
golangci-lint run --config=.golangci.yml

# Security check
gosec ./...

# Tests
go test -race -coverprofile=coverage.out -covermode=atomic ./...

# Build
go build -o build/agent .
```

## Coverage Reports

Coverage reports are generated automatically:

- `coverage.out` - Coverage data file
- `coverage.html` - HTML coverage report

View coverage in browser:
```bash
open coverage.html
```

View coverage in terminal:
```bash
go tool cover -func=coverage.out
```

## Linting Configuration

The project uses `golangci-lint` with the following enabled linters:

- `errcheck` - Check for unchecked errors
- `errorlint` - Check error handling patterns
- `goconst` - Find repeated string constants
- `godot` - Check documentation comments
- `gofmt` - Check formatting
- `goimports` - Check import organization
- `gosec` - Security analysis
- `gosimple` - Simplify code suggestions
- `govet` - Go vet analysis
- `ineffassign` - Find ineffective assignments
- `misspell` - Find commonly misspelled words
- `nestif` - Check nested if statements
- `revive` - General purpose linter
- `staticcheck` - Static analysis
- `typecheck` - Type checking
- `unconvert` - Remove unnecessary type conversions
- `unused` - Find unused code
- `whitespace` - Check whitespace usage

## Security Analysis

The project includes security analysis using `gosec` which checks for:

- SQL injection vulnerabilities
- Command injection
- File path traversal
- Weak cryptographic practices
- Hard-coded credentials
- And more security issues

## Best Practices

1. **Before Committing**: Run `make ci` or `./scripts/ci.sh` to ensure all checks pass
2. **Auto-fix Issues**: Use `make format` and `make lint-fix` to automatically fix common issues
3. **Write Tests**: Maintain good test coverage for new features
4. **Security**: Address any security issues found by `gosec`
5. **Documentation**: Keep code well-documented with proper comments

## Troubleshooting

### Common Issues

1. **Formatting Errors**: Run `make format` to fix
2. **Import Issues**: Run `goimports -w .` to fix import organization
3. **Linting Errors**: Check `.golangci.yml` for disabled rules or run `make lint-fix`
4. **Security Issues**: Review `gosec` output and address genuine security concerns

### Tool Installation Issues

If tools are not found, install them:

```bash
# Install all tools
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest
``` 
