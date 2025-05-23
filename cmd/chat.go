package cmd

import (
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var chatCmd = &cobra.Command{
	Use:   "chat",
	Short: "Start the agent chat TUI",
	Long:  `Launch the terminal user interface for chatting with the agent.`,
	Run: func(cmd *cobra.Command, args []string) {
		log.Info("Starting agent chat interface...\n")
		log.Info("Chat TUI functionality will be implemented in future work.\n")
	},
}

func init() {
	rootCmd.AddCommand(chatCmd)
}
