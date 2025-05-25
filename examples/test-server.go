// Test server to simulate agent.nvim plugin for testing the chat interface
package main

import (
	"fmt"
	"log"
	"net"
	"time"

	"github.com/vmihailenco/msgpack/v5"
)

type message struct {
	ID      int         `msgpack:"id" json:"id"`
	Type    string      `msgpack:"type" json:"type"`
	Content interface{} `msgpack:"content" json:"content"`
}

type chatMessage struct {
	Type    string `msgpack:"type" json:"type"`
	Content string `msgpack:"content" json:"content"`
}

func main() {
	// Listen on port 7070 (same as agent.nvim)
	listener, err := net.Listen("tcp", "127.0.0.1:7070")
	if err != nil {
		log.Fatal("Failed to start server:", err)
	}
	defer listener.Close()

	fmt.Println("Test server listening on 127.0.0.1:7070")
	fmt.Println("This simulates the agent.nvim plugin for testing the chat interface")

	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Println("Failed to accept connection:", err)
			continue
		}

		go handleConnection(conn)
	}
}

func handleConnection(conn net.Conn) {
	defer conn.Close()
	fmt.Println("Client connected:", conn.RemoteAddr())

	decoder := msgpack.NewDecoder(conn)
	encoder := msgpack.NewEncoder(conn)

	for {
		var msg message
		err := decoder.Decode(&msg)
		if err != nil {
			if err.Error() != "EOF" {
				log.Println("Failed to decode message:", err)
			}
			break
		}

		fmt.Printf("Received message: ID=%d, Type=%s\n", msg.ID, msg.Type)

		// Echo the message back with a response
		response := message{
			ID:   msg.ID,
			Type: "message",
			Content: map[string]interface{}{
				"content": fmt.Sprintf("Echo: Received your %s message!", msg.Type),
			},
		}

		err = encoder.Encode(response)
		if err != nil {
			log.Println("Failed to send response:", err)
			break
		}

		// Send a notification after a short delay
		go func() {
			time.Sleep(2 * time.Second)
			notification := message{
				ID:   0,
				Type: "notification",
				Content: map[string]interface{}{
					"content": "This is a test notification from the agent!",
				},
			}
			if err := encoder.Encode(notification); err != nil {
				log.Printf("Failed to encode notification: %v", err)
			}
		}()
	}

	fmt.Println("Client disconnected:", conn.RemoteAddr())
}
