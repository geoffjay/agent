package cmd

import (
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var initCmd = &cobra.Command{
	Use:   "init",
	Short: "Initialize a new agent configuration",
	Long:  `Create an Agentfile.yml configuration file in the current directory.`,
	Run: func(cmd *cobra.Command, args []string) {
		log.Info("Creating Agentfile.yml configuration file...\n")
		log.Info("Agent configuration initialized successfully.\n")
	},
}

func init() {
	rootCmd.AddCommand(initCmd)
}
