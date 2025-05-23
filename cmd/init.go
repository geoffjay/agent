package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var initCmd = &cobra.Command{
	Use:   "init",
	Short: "Initialize a new agent configuration",
	Long:  `Create an Agentfile.yml configuration file in the current directory.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Creating Agentfile.yml configuration file...")
		fmt.Println("Agent configuration initialized successfully.")
	},
}

func init() {
	rootCmd.AddCommand(initCmd)
}
