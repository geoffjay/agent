package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show the status of running agents",
	Long:  `Display the current status of all running agent processes.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Checking agent status...")
		fmt.Println("No agents currently running.")
	},
}

func init() {
	rootCmd.AddCommand(statusCmd)
}
