package cmd

import (
	"fmt"
	"net"
	"sync"
	"time"

	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/vmihailenco/msgpack/v5"
)

type AgentService struct {
	listener   net.Listener
	clients    map[string]*Client
	clientsMux sync.RWMutex
	messageID  int
	messageMux sync.Mutex
}

type Client struct {
	ID       string
	Type     string // "chat" or "nvim"
	Conn     net.Conn
	Service  *AgentService
	LastSeen time.Time
}

type Message struct {
	ID      int         `msgpack:"id" json:"id"`
	Type    string      `msgpack:"type" json:"type"`
	From    string      `msgpack:"from,omitempty" json:"from,omitempty"`
	To      string      `msgpack:"to,omitempty" json:"to,omitempty"`
	Content interface{} `msgpack:"content" json:"content"`
}

func NewAgentService() *AgentService {
	return &AgentService{
		clients: make(map[string]*Client),
	}
}

func (s *AgentService) Start(address string) error {
	listener, err := net.Listen("tcp", address)
	if err != nil {
		return fmt.Errorf("failed to start server: %w", err)
	}

	s.listener = listener
	log.Infof("Agent service listening on %s", address)

	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Errorf("Failed to accept connection: %v", err)
			continue
		}

		go s.handleConnection(conn)
	}
}

func (s *AgentService) handleConnection(conn net.Conn) {
	defer conn.Close()

	clientID := conn.RemoteAddr().String()
	log.Infof("New client connected: %s", clientID)

	client := &Client{
		ID:       clientID,
		Conn:     conn,
		Service:  s,
		LastSeen: time.Now(),
	}

	s.clientsMux.Lock()
	s.clients[clientID] = client
	s.clientsMux.Unlock()

	defer func() {
		s.clientsMux.Lock()
		delete(s.clients, clientID)
		s.clientsMux.Unlock()
		log.Infof("Client disconnected: %s", clientID)
	}()

	decoder := msgpack.NewDecoder(conn)
	encoder := msgpack.NewEncoder(conn)

	for {
		var msg Message
		err := decoder.Decode(&msg)
		if err != nil {
			if err.Error() != "EOF" {
				log.Debugf("Failed to decode message from %s: %v", clientID, err)
			}
			break
		}

		client.LastSeen = time.Now()
		msg.From = clientID

		log.Debugf("Received message from %s: type=%s", clientID, msg.Type)

		// Handle client identification
		if msg.Type == "identify" {
			if contentMap, ok := msg.Content.(map[string]interface{}); ok {
				if clientType, ok := contentMap["client_type"].(string); ok {
					client.Type = clientType
					log.Infof("Client %s identified as: %s", clientID, clientType)
				}
			}
			continue
		}

		// Route the message
		s.routeMessage(msg, client, encoder)
	}
}

func (s *AgentService) routeMessage(msg Message, sender *Client, senderEncoder *msgpack.Encoder) {
	switch msg.Type {
	case "chat":
		// Route chat messages to nvim clients
		s.routeToType("nvim", msg)

		// Send acknowledgment back to chat client
		ack := Message{
			ID:   msg.ID,
			Type: "ack",
			Content: map[string]interface{}{
				"message": "Message sent to agent",
			},
		}
		s.sendToClient(sender, ack, senderEncoder)

	case "buffer", "selection":
		// Route code-related messages to chat clients for processing
		s.routeToType("chat", msg)

	case "response", "message", "notification", "edit", "error":
		// Route responses back to the appropriate clients
		if sender.Type == "nvim" {
			s.routeToType("chat", msg)
		} else if sender.Type == "chat" {
			s.routeToType("nvim", msg)
		}

	case "status":
		// Handle status requests
		status := s.getStatus()
		response := Message{
			ID:      msg.ID,
			Type:    "status_response",
			Content: status,
		}
		s.sendToClient(sender, response, senderEncoder)

	default:
		// Broadcast unknown message types to all other clients
		s.broadcastMessage(msg, sender)
	}
}

func (s *AgentService) routeToType(clientType string, msg Message) {
	s.clientsMux.RLock()
	defer s.clientsMux.RUnlock()

	for _, client := range s.clients {
		if client.Type == clientType {
			encoder := msgpack.NewEncoder(client.Conn)
			s.sendToClient(client, msg, encoder)
		}
	}
}

func (s *AgentService) broadcastMessage(msg Message, sender *Client) {
	s.clientsMux.RLock()
	defer s.clientsMux.RUnlock()

	for _, client := range s.clients {
		if client.ID != sender.ID {
			encoder := msgpack.NewEncoder(client.Conn)
			s.sendToClient(client, msg, encoder)
		}
	}
}

func (s *AgentService) sendToClient(client *Client, msg Message, encoder *msgpack.Encoder) {
	// Assign message ID if not set
	if msg.ID == 0 {
		s.messageMux.Lock()
		s.messageID++
		msg.ID = s.messageID
		s.messageMux.Unlock()
	}

	err := encoder.Encode(msg)
	if err != nil {
		log.Errorf("Failed to send message to client %s: %v", client.ID, err)
	} else {
		log.Debugf("Sent message to %s: type=%s, id=%d", client.ID, msg.Type, msg.ID)
	}
}

func (s *AgentService) getStatus() map[string]interface{} {
	s.clientsMux.RLock()
	defer s.clientsMux.RUnlock()

	clients := make([]map[string]interface{}, 0, len(s.clients))
	for _, client := range s.clients {
		clients = append(clients, map[string]interface{}{
			"id":        client.ID,
			"type":      client.Type,
			"last_seen": client.LastSeen.Unix(),
		})
	}

	return map[string]interface{}{
		"clients":      clients,
		"client_count": len(s.clients),
		"uptime":       time.Now().Unix(),
	}
}

var serveCmd = &cobra.Command{
	Use:   "serve",
	Short: "Start the agent service broker",
	Long:  `Start the agent service that brokers communication between chat clients and neovim plugins.`,
	Run: func(cmd *cobra.Command, args []string) {
		address := "127.0.0.1:7070"
		if len(args) > 0 {
			address = args[0]
		}

		log.Info("Starting agent service...")
		service := NewAgentService()

		if err := service.Start(address); err != nil {
			log.Fatal("Failed to start agent service:", err)
		}
	},
}

func init() {
	rootCmd.AddCommand(serveCmd)
}
