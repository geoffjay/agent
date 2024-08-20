package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var askCmd = &cobra.Command{
	Use:   "ask",
	Short: "Query the agent service",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("ask")
	},
}
