package core

import (
	"context"
	"os"
	"sync"

	conf "github.com/geoffjay/agent/config"

	log "github.com/sirupsen/logrus"
)

// Agent represents the main agent that runs in the background.
type Agent struct{}

func (a *Agent) init() {}

// Run starts the agent and waits for the context to be cancelled.
func (a *Agent) Run(ctx context.Context, wg *sync.WaitGroup) {
	defer wg.Done()

	config, err := conf.GetConfig()
	if err != nil {
		log.Error("Failed to get config: ", err)
		os.Exit(1)
	}

	go func() {
		log.Info("Agent is running")
		log.Infof("Config: %s", config.Name)
	}()

	<-ctx.Done()
}
