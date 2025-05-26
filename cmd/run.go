package cmd

import (
	"context"
	"os"
	"os/signal"
	"sync"
	"syscall"

	"github.com/geoffjay/agent/internal/agent"

	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

var runCmd = &cobra.Command{
	Use:   "run",
	Short: "Start the agent as a daemonized service",
	Long:  `Start the agent process that runs in the background as a service.`,
	Run: func(cmd *cobra.Command, args []string) {
		log.Info("Starting agent service...\n")
		runAgent()
	},
}

func init() {
	rootCmd.AddCommand(runCmd)
}

func runAgent() {
	agent := agent.Agent{}

	ctx, cancelFunc := context.WithCancel(context.Background())
	wg := &sync.WaitGroup{}

	wg.Add(1)
	go agent.Run(ctx, wg)

	log.Info("Agent service is running. Press Ctrl+C to stop.\n")

	termChan := make(chan os.Signal, 1)
	signal.Notify(termChan, syscall.SIGINT, syscall.SIGTERM)
	<-termChan

	log.Info("Shutting down agent service...\n")
	cancelFunc()
	wg.Wait()
	log.Info("Agent service stopped.")
}
