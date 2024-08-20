package cmd

import (
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"

	"github.com/spf13/cobra"
	"google.golang.org/grpc"
	"google.golang.org/grpc/health"
	"google.golang.org/grpc/health/grpc_health_v1"
	"google.golang.org/grpc/reflection"
)

const (
	PROTOCOL = "unix"
	SOCKET   = "/tmp/agent.sock"
)

var serveCmd = &cobra.Command{
	Use:   "serve",
	Short: "Run the agent service",
	Run:   serve,
}

func init() {
	rootCmd.AddCommand(serveCmd)
}

func serve(cmd *cobra.Command, args []string) {
	if _, err := os.Stat(SOCKET); !os.IsNotExist(err) {
		if err := os.RemoveAll(SOCKET); err != nil {
			log.Fatal(err)
		}
	}

	ln, err := net.Listen(PROTOCOL, SOCKET)
	if err != nil {
		log.Fatal(err)
	}

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		os.Remove(SOCKET)
		os.Exit(1)
	}()

	srv := grpc.NewServer()
	grpc_health_v1.RegisterHealthServer(srv, health.NewServer())
	reflection.Register(srv)

	log.Printf("gRPC running on unix socket %s", SOCKET)
	log.Fatal(srv.Serve(ln))
}
