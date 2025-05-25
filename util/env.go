package util

import "os"

// Getenv returns the value of the environment variable named by the key.
// If the variable is not present, it returns the fallback value.
func Getenv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
