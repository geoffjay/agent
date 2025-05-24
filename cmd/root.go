package cmd

import (
	"os"

	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "agent",
	Short: "Agent is used to launch and interact with autonomous agents",
	Long:  `Agent is a CLI tool for managing autonomous agents. Use the subcommands to initialize, run, and manage agents.`,
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		log.Error(err)
		os.Exit(1)
	}
}
