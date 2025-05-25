package config

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestPrepare(t *testing.T) {
	tests := []struct {
		name     string
		filename string
		wantErr  bool
	}{
		{
			name:     "Valid YAML",
			filename: "test.yaml",
			wantErr:  false,
		},
		{
			name:     "Valid YML",
			filename: "test.yml",
			wantErr:  false,
		},
		{
			name:     "Valid JSON",
			filename: "test.json",
			wantErr:  false,
		},
		{
			name:     "Valid TOML",
			filename: "test.toml",
			wantErr:  false,
		},
		{
			name:     "Invalid extension",
			filename: "test.txt",
			wantErr:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cfg, err := prepare(tt.filename)
			if tt.wantErr {
				assert.Error(t, err)
				assert.Nil(t, cfg)
			} else {
				assert.NoError(t, err)
				assert.NotNil(t, cfg)
			}
		})
	}
}

func TestLoadConfig(t *testing.T) {
	// Create a temporary directory
	tmpDir, err := os.MkdirTemp("", "config-test")
	assert.NoError(t, err)
	defer func() {
		err := os.RemoveAll(tmpDir)
		assert.NoError(t, err)
	}()

	// Create a valid config file
	validConfig := `name: TestApp`
	validFile := filepath.Join(tmpDir, "valid.yml")
	err = os.WriteFile(validFile, []byte(validConfig), 0600)
	assert.NoError(t, err)

	// Create an invalid config file
	invalidConfig := `name: TestApp: invalid`
	invalidFile := filepath.Join(tmpDir, "invalid.yml")
	err = os.WriteFile(invalidFile, []byte(invalidConfig), 0600)
	assert.NoError(t, err)

	// Create a file that can't be unmarshalled properly
	badStructConfig := `name: 123` // This should cause an unmarshal error when strict decoding
	badStructFile := filepath.Join(tmpDir, "badstruct.yml")
	err = os.WriteFile(badStructFile, []byte(badStructConfig), 0600)
	assert.NoError(t, err)

	// Test with valid config
	t.Run("Valid config", func(t *testing.T) {
		var cfg Config
		err := LoadConfig(validFile, &cfg)
		assert.NoError(t, err)
		assert.Equal(t, "TestApp", cfg.Name)
	})

	// Test with invalid file extension
	t.Run("Invalid file extension", func(t *testing.T) {
		invalidExtFile := filepath.Join(tmpDir, "invalid.txt")
		err = os.WriteFile(invalidExtFile, []byte(validConfig), 0600)
		assert.NoError(t, err)

		var cfg Config
		err := LoadConfig(invalidExtFile, &cfg)
		assert.Error(t, err)
	})

	// Test with invalid config content
	t.Run("Invalid config content", func(t *testing.T) {
		var cfg Config
		err := LoadConfig(invalidFile, &cfg)
		assert.Error(t, err)
	})

	// Test with non-existent file
	t.Run("Non-existent file", func(t *testing.T) {
		var cfg Config
		err := LoadConfig(filepath.Join(tmpDir, "nonexistent.yml"), &cfg)
		assert.Error(t, err)
	})

	// Test with unmarshalling error
	t.Run("Unmarshal error", func(t *testing.T) {
		// Using a string to unmarshal into a struct that expects different types
		type ComplexConfig struct {
			Name int `mapstructure:"name"`
		}
		var cfg ComplexConfig
		err := LoadConfig(validFile, &cfg)
		assert.Error(t, err)
	})

	// Test environment variable override
	t.Run("Environment variable override", func(t *testing.T) {
		err := os.Setenv("AGENT_NAME", "EnvApp")
		assert.NoError(t, err)
		defer func() {
			err := os.Unsetenv("AGENT_NAME")
			assert.NoError(t, err)
		}()

		var cfg Config
		err = LoadConfig(validFile, &cfg)
		assert.NoError(t, err)
		assert.Equal(t, "EnvApp", cfg.Name)
	})
}

func TestGetConfig(t *testing.T) {
	// Create a temporary directory
	tmpDir, err := os.MkdirTemp("", "config-test")
	assert.NoError(t, err)
	defer func() {
		err := os.RemoveAll(tmpDir)
		assert.NoError(t, err)
	}()

	// Save current directory
	currentDir, err := os.Getwd()
	assert.NoError(t, err)
	defer func() {
		err := os.Chdir(currentDir)
		assert.NoError(t, err)
	}()

	// Change to temp directory
	err = os.Chdir(tmpDir)
	assert.NoError(t, err)

	// Test with non-existent file
	t.Run("Non-existent file", func(t *testing.T) {
		err := os.Setenv("AGENTFILE", "nonexistent.yml")
		assert.NoError(t, err)
		defer func() {
			err := os.Unsetenv("AGENTFILE")
			assert.NoError(t, err)
		}()

		cfg, err := GetConfig()
		assert.Error(t, err)
		assert.Nil(t, cfg)
	})

	// Create a valid config file
	validConfig := `name: TestApp`
	validFile := filepath.Join(tmpDir, "Agentfile.yml")
	err = os.WriteFile(validFile, []byte(validConfig), 0600)
	assert.NoError(t, err)

	// Test with default config file
	t.Run("Default config file", func(t *testing.T) {
		err = os.Unsetenv("AGENTFILE")
		assert.NoError(t, err)

		cfg, err := GetConfig()
		assert.NoError(t, err)
		assert.NotNil(t, cfg)
		assert.Equal(t, "TestApp", cfg.Name)
	})

	// Test with custom config file
	t.Run("Custom config file", func(t *testing.T) {
		customConfig := `name: CustomApp`
		customFile := filepath.Join(tmpDir, "custom.yml")
		err = os.WriteFile(customFile, []byte(customConfig), 0600)
		assert.NoError(t, err)

		err = os.Setenv("AGENTFILE", "custom.yml")
		assert.NoError(t, err)
		defer func() {
			err := os.Unsetenv("AGENTFILE")
			assert.NoError(t, err)
		}()

		cfg, err := GetConfig()
		assert.NoError(t, err)
		assert.NotNil(t, cfg)
		assert.Equal(t, "CustomApp", cfg.Name)
	})

	// Test with load config error
	t.Run("Load config error", func(t *testing.T) {
		invalidConfig := `name: TestApp: invalid`
		invalidFile := filepath.Join(tmpDir, "invalid.yml")
		err = os.WriteFile(invalidFile, []byte(invalidConfig), 0600)
		assert.NoError(t, err)

		err = os.Setenv("AGENTFILE", "invalid.yml")
		assert.NoError(t, err)
		defer func() {
			err := os.Unsetenv("AGENTFILE")
			assert.NoError(t, err)
		}()

		cfg, err := GetConfig()
		assert.Error(t, err)
		assert.Nil(t, cfg)
	})
}
