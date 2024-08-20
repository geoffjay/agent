package cmd

import (
	"context"
	"log"
	"net"
	"time"

	"github.com/spf13/cobra"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/health/grpc_health_v1"
)

var askCmd = &cobra.Command{
	Use:   "ask",
	Short: "Query the agent service",
	Run:   ask,
}

func init() {
	rootCmd.AddCommand(askCmd)
}

func ask(cmd *cobra.Command, args []string) {
	var (
		rootCtx          = context.Background()
		mainCtx, mainCxl = context.WithCancel(rootCtx)
	)
	defer mainCxl()

	var (
		credentials = insecure.NewCredentials()
		dialer      = func(ctx context.Context, addr string) (net.Conn, error) {
			var d net.Dialer
			log.Printf("Dialing %s", addr)
			return d.DialContext(ctx, PROTOCOL, addr)
		}
		options = []grpc.DialOption{
			grpc.WithTransportCredentials(credentials),
			grpc.WithContextDialer(dialer),
		}
	)

	log.Printf("Querying agent service on unix socket %s", SOCKET)
	conn, err := grpc.NewClient(SOCKET, options...)
	if err != nil {
		panic(err)
	}
	defer conn.Close()

	health := grpc_health_v1.NewHealthClient(conn)
	ctx, cancel := context.WithTimeout(mainCtx, 1*time.Second)
	defer cancel()
	// ctx := context.Background()

	log.Print("Querying health status")
	_, err = health.Check(ctx, &grpc_health_v1.HealthCheckRequest{})
	if err != nil {
		log.Fatal(err)
	}
}
