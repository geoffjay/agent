package cmd

import (
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var statsCmd = &cobra.Command{
	Use:   "stats",
	Short: "Show statistics of running agents",
	Long:  `Display performance and usage statistics for running agents.`,
	Run: func(cmd *cobra.Command, args []string) {
		log.Info("Gathering agent statistics...\n")
		log.Info("Agent statistics functionality will be implemented in future work.\n")
	},
}

func init() {
	rootCmd.AddCommand(statsCmd)
}
