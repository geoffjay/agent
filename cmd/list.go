package cmd

import (
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List currently running agents",
	Long:  `Display a list of all currently running agent processes.`,
	Run: func(cmd *cobra.Command, args []string) {
		log.Info("Listing running agents...\n")
		log.Info("No agents currently running.\n")
	},
}

func init() {
	rootCmd.AddCommand(listCmd)
}
