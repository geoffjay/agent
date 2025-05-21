// Package config provides functionality for loading and accessing application configuration.
//
// Configuration can be loaded from YAML, JSON, or TOML files, and values can be
// overridden using environment variables with the prefix "AGENT_".
//
// Example usage:
//
//	cfg, err := config.GetConfig()
//	if err != nil {
//		log.Fatalf("Failed to load config: %v", err)
//	}
//	fmt.Println("Agent name:", cfg.Name)
package config

import (
	"errors"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/geoffjay/agent/util"

	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
)

// Config represents the application configuration structure.
// Add new configuration fields to this struct as needed.
type Config struct {
	// Name is the name of the agent.
	Name string `mapstructure:"name"`
}

// Environment variable prefix used for configuration overrides.
const envPrefix = "AGENT"

// prepare initializes a viper configuration instance for the given filename.
// It determines the file type from the extension and configures viper accordingly.
// Supported extensions are: yaml, yml, json, and toml.
func prepare(filename string) (*viper.Viper, error) {
	config := viper.New()

	var extension string

	regex := regexp.MustCompile("((y(a)?ml)|json|toml)$")
	base := filepath.Base(filename)
	if regex.Match([]byte(base)) {
		// strip the file type for viper
		parts := strings.Split(filepath.Base(filename), ".")
		base = strings.Join(parts[:len(parts)-1], ".")
		extension = parts[len(parts)-1]
	} else {
		return nil, errors.New("configuration does not support that extension type")
	}

	config.SetConfigName(base)
	config.SetConfigType(extension)
	config.SetConfigFile(filename)
	config.AddConfigPath(filepath.Dir(filename))

	return config, nil
}

// LoadConfig reads in a configuration file from a set of locations and
// deserializes it into a Config instance.
//
// The function accepts the following parameters:
//   - filename: The path to the configuration file.
//   - c: A pointer to the struct that will be populated with the configuration values.
//
// Environment variables with the prefix "AGENT_" can override configuration values.
// For example, AGENT_NAME will override the "name" configuration value.
//
// Returns an error if the configuration cannot be loaded or parsed.
func LoadConfig(filename string, c interface{}) error {
	config, err := prepare(filename)
	if err != nil {
		return err
	}

	err = config.ReadInConfig()
	if err != nil {
		return err
	}

	config.SetEnvPrefix(envPrefix)
	config.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	config.AutomaticEnv()

	err = config.Unmarshal(&c)
	if err != nil {
		return err
	}

	return nil
}

// GetConfig returns the application configuration.
//
// By default, it looks for a file named "Agentfile.yml" in the current directory.
// This can be overridden by setting the AGENTFILE environment variable.
//
// Returns:
//   - A pointer to the Config struct containing the loaded configuration.
//   - An error if the configuration file doesn't exist or cannot be loaded.
func GetConfig() (*Config, error) {
	var config *Config

	filename := util.Getenv("AGENTFILE", "Agentfile.yml")
	_, err := os.Stat(filename)
	if errors.Is(err, os.ErrNotExist) {
		return nil, err
	}

	if err := LoadConfig(filename, &config); err != nil {
		return nil, err
	}

	log.Tracef("config: %+v", config)

	return config, nil
}
