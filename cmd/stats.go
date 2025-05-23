package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var statsCmd = &cobra.Command{
	Use:   "stats",
	Short: "Show statistics of running agents",
	Long:  `Display performance and usage statistics for running agents.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Gathering agent statistics...")
		fmt.Println("Agent statistics functionality will be implemented in future work.")
	},
}

func init() {
	rootCmd.AddCommand(statsCmd)
}
