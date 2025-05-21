# Configuration Guide

This document explains how to configure the agent application through configuration files and environment variables.

## Configuration Files

The agent application uses a configuration file to control its behavior. By default, it looks for a file named `Agentfile.yml` in the current directory.

### Supported Formats

The following file formats are supported:

- **YAML**: `.yaml` or `.yml` extension
- **JSON**: `.json` extension
- **TOML**: `.toml` extension

### Basic Configuration

Here's a basic example of a configuration file in each supported format:

**YAML** (Agentfile.yml):
```yaml
name: "MyAgent"
```

**JSON** (Agentfile.json):
```json
{
  "name": "MyAgent"
}
```

**TOML** (Agentfile.toml):
```toml
name = "MyAgent"
```

### Configuration Location

You can specify a custom configuration file location using the `AGENTFILE` environment variable:

```bash
# Use a custom configuration file
export AGENTFILE=/path/to/my/custom-config.yml
```

## Environment Variables

All configuration options can be overridden using environment variables. The environment variables use the `AGENT_` prefix followed by the configuration key in uppercase.

For example, to override the `name` configuration:

```bash
export AGENT_NAME="OverriddenAgentName"
```

For nested configuration values, use underscores to separate the levels:

```bash
# For a configuration like:
# database:
#   host: localhost
#   port: 5432
export AGENT_DATABASE_HOST="db.example.com"
export AGENT_DATABASE_PORT="5433"
```

## Configuration Options

The following configuration options are available:

| Option | Type | Description | Environment Variable |
|--------|------|-------------|---------------------|
| `name` | String | The name of the agent | `AGENT_NAME` |

## Best Practices

1. **Use version control**: Keep your configuration files in version control with sensitive information excluded.
2. **Use environment variables for environment-specific settings**: Use the same configuration file across environments, but override specific values with environment variables.
3. **Validate your configuration files**: Before deploying, validate your configuration files to ensure they're valid YAML, JSON, or TOML.
4. **Document changes**: When you make changes to the configuration, document the changes and their effects.

## Examples

### Development Configuration

```yaml
# Agentfile.yml
name: "DevAgent"
```

### Production Configuration

```yaml
# Agentfile.yml
name: "ProdAgent"
```

With environment variables:

```bash
export AGENT_NAME="ProdAgent-1"
```

## Troubleshooting

1. **Configuration not found**: Ensure your configuration file exists and is in the correct location. If using a custom location, verify the `AGENTFILE` environment variable is set correctly.
2. **Invalid configuration**: Check that your configuration file is valid YAML, JSON, or TOML. Use a linter to validate the format.
3. **Environment variables not taking effect**: Verify that environment variables are correctly set with the `AGENT_` prefix and that the application has access to these variables. 
