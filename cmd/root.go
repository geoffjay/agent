package cmd

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/geoffjay/agent/core"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "agent",
	Short: "Agent is a helpful coder buddy",
	Run:   runAgent,
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func runAgent(_ *cobra.Command, _ []string) {
	agent := core.Agent{}

	ctx, cancelFunc := context.WithCancel(context.Background())
	wg := &sync.WaitGroup{}

	wg.Add(1)
	agent.Run(ctx, wg)

	go func() {
		for {
			fmt.Println("Hello, world!")
			<-time.After(1 * time.Second)
		}
	}()

	termChan := make(chan os.Signal, 1)
	signal.Notify(termChan, syscall.SIGINT, syscall.SIGTERM)
	<-termChan

	cancelFunc()
	wg.Wait()
}
