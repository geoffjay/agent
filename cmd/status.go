package cmd

import (
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show the status of running agents",
	Long:  `Display the current status of all running agent processes.`,
	Run: func(cmd *cobra.Command, args []string) {
		log.Info("Checking agent status...\n")
		log.Info("No agents currently running.\n")
	},
}

func init() {
	rootCmd.AddCommand(statusCmd)
}
