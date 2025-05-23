package cmd

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"sync"
	"syscall"

	"github.com/geoffjay/agent/core"
	"github.com/spf13/cobra"
)

var runCmd = &cobra.Command{
	Use:   "run",
	Short: "Start the agent as a daemonized service",
	Long:  `Start the agent process that runs in the background as a service.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Starting agent service...")
		runAgent()
	},
}

func init() {
	rootCmd.AddCommand(runCmd)
}

func runAgent() {
	agent := core.Agent{}

	ctx, cancelFunc := context.WithCancel(context.Background())
	wg := &sync.WaitGroup{}

	wg.Add(1)
	agent.Run(ctx, wg)

	fmt.Println("Agent service is running. Press Ctrl+C to stop.")

	termChan := make(chan os.Signal, 1)
	signal.Notify(termChan, syscall.SIGINT, syscall.SIGTERM)
	<-termChan

	fmt.Println("\nShutting down agent service...")
	cancelFunc()
	wg.Wait()
	fmt.Println("Agent service stopped.")
}
