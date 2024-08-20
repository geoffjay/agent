package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "agent",
	Short: "Agent is a helpful coder buddy",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("root")
	},
}

func Execute() {
	rootCmd.AddCommand(askCmd)

	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
