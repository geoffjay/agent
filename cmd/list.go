package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List currently running agents",
	Long:  `Display a list of all currently running agent processes.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Listing running agents...")
		fmt.Println("No agents currently running.")
	},
}

func init() {
	rootCmd.AddCommand(listCmd)
}
