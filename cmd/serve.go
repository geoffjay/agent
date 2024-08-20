package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var serveCmd = &cobra.Command{
	Use:   "serve",
	Short: "Run the agent service",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("serve")
	},
}
