package cmd

import (
	"fmt"
	"net"
	"sync"
	"time"

	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	msgpack "github.com/vmihailenco/msgpack/v5"
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

	encoder := msgpack.NewEncoder(conn)
	buffer := make([]byte, 0, 4096) // Buffer for accumulating frame data

	for {
		// Read data from connection
		readBuf := make([]byte, 4096)
		n, err := conn.Read(readBuf)
		if err != nil {
			if err.Error() != "EOF" {
				log.Debugf("Failed to read from connection %s: %v", clientID, err)
			}
			break
		}

		// Accumulate data in buffer
		buffer = append(buffer, readBuf[:n]...)

		// Process complete frames from buffer
		for len(buffer) >= 4 {
			// Read frame length (big-endian 4 bytes)
			length := uint32(buffer[0])<<24 | uint32(buffer[1])<<16 | uint32(buffer[2])<<8 | uint32(buffer[3])

			// Check if we have the complete frame
			if len(buffer) < int(4+length) {
				// Need more data for complete frame
				break
			}

			// Extract the frame data
			frameData := buffer[4 : 4+length]

			// Remove processed frame from buffer
			buffer = buffer[4+length:]

			// Decode the frame
			var msg Message
			err := msgpack.Unmarshal(frameData, &msg)
			if err != nil {
				log.Debugf("Failed to decode framed message from %s: %v", clientID, err)
				continue
			}

			// Process the message
			client.LastSeen = time.Now()
			msg.From = clientID

			log.Debugf("Received framed message from %s (%s): type=%s, content=%+v", clientID, client.Type, msg.Type, msg.Content)

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
}

func (s *AgentService) routeMessage(msg Message, sender *Client, senderEncoder *msgpack.Encoder) {
	log.Debugf("Routing message: type=%s, from=%s (%s)", msg.Type, sender.ID, sender.Type)

	switch msg.Type {
	case "chat":
		// Route chat messages to nvim clients
		log.Debugf("Routing chat message to nvim clients")
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

	targetClients := 0
	for _, client := range s.clients {
		if client.Type == clientType {
			targetClients++
		}
	}

	log.Debugf("Routing to %s clients: found %d targets", clientType, targetClients)

	for _, client := range s.clients {
		if client.Type == clientType {
			encoder := msgpack.NewEncoder(client.Conn)
			log.Debugf("Sending message to %s client %s", clientType, client.ID)
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

	// Encode message to bytes first
	data, err := msgpack.Marshal(msg)
	if err != nil {
		log.Errorf("Failed to marshal message for client %s: %v", client.ID, err)
		return
	}

	// Send with 4-byte length prefix for framing (big-endian)
	dataLen := len(data)
	if dataLen < 0 || dataLen > 0xFFFFFFFF {
		log.Errorf("Message too large: %d bytes", dataLen)
		return
	}
	length := uint32(dataLen)
	lengthBytes := make([]byte, 4)
	lengthBytes[0] = byte(length >> 24)
	lengthBytes[1] = byte(length >> 16)
	lengthBytes[2] = byte(length >> 8)
	lengthBytes[3] = byte(length)

	// Write length prefix + data as one write to ensure atomicity
	frame := append(lengthBytes, data...)
	_, err = client.Conn.Write(frame)
	if err != nil {
		log.Errorf("Failed to send message to client %s: %v", client.ID, err)
	} else {
		log.Debugf("Sent framed message to %s: type=%s, id=%d, frame_size=%d", client.ID, msg.Type, msg.ID, len(frame))
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
		verbose, _ := cmd.Flags().GetBool("verbose")
		if verbose {
			log.SetLevel(log.DebugLevel)
			log.Debug("Debug logging enabled")
		}

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
	serveCmd.Flags().BoolP("verbose", "v", false, "Enable verbose debug logging")
	rootCmd.AddCommand(serveCmd)
}
