package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var chatCmd = &cobra.Command{
	Use:   "chat",
	Short: "Start the agent chat TUI",
	Long:  `Launch the terminal user interface for chatting with the agent.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Starting agent chat interface...")
		fmt.Println("Chat TUI functionality will be implemented in future work.")
	},
}

func init() {
	rootCmd.AddCommand(chatCmd)
}
