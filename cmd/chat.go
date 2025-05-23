package cmd

import (
	"encoding/json"
	"net"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/textarea"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/vmihailenco/msgpack/v5"
)

type chatModel struct {
	ready     bool
	width     int
	height    int
	textarea  textarea.Model
	viewport  viewport.Model
	messages  []string
	conn      net.Conn
	connected bool
	messageID int
	err       error
}

type message struct {
	ID      int         `msgpack:"id" json:"id"`
	Type    string      `msgpack:"type" json:"type"`
	Content interface{} `msgpack:"content" json:"content"`
}

type chatMessage struct {
	Type    string `msgpack:"type" json:"type"`
	Content string `msgpack:"content" json:"content"`
}

var (
	// Styles
	titleStyle = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("#7C3AED")).
			Border(lipgloss.RoundedBorder()).
			BorderForeground(lipgloss.Color("#7C3AED")).
			Padding(0, 1).
			MarginBottom(1)

	messageStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#FBBF24"))

	userMessageStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#10B981")).
				Bold(true)

	agentMessageStyle = lipgloss.NewStyle().
				Foreground(lipgloss.Color("#3B82F6"))

	errorStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#EF4444")).
			Bold(true)

	statusStyle = lipgloss.NewStyle().
			Foreground(lipgloss.Color("#6B7280")).
			Italic(true)
)

func initialModel() chatModel {
	ta := textarea.New()
	ta.Placeholder = "Type your message here... (Ctrl+S to send, Ctrl+C to quit)"
	ta.Focus()
	ta.CharLimit = 0
	ta.SetWidth(80)
	ta.SetHeight(3)
	ta.ShowLineNumbers = false

	vp := viewport.New(80, 20)
	vp.SetContent("")

	return chatModel{
		textarea: ta,
		viewport: vp,
		messages: []string{},
		ready:    false,
	}
}

func (m chatModel) Init() tea.Cmd {
	return tea.Batch(
		textarea.Blink,
		m.connectToAgent(),
	)
}

func (m chatModel) connectToAgent() tea.Cmd {
	return func() tea.Msg {
		conn, err := net.Dial("tcp", "127.0.0.1:7070")
		if err != nil {
			return connectionErrorMsg{err}
		}

		// Send client identification
		identifyMsg := message{
			ID:   1,
			Type: "identify",
			Content: map[string]interface{}{
				"client_type": "chat",
			},
		}

		encoder := msgpack.NewEncoder(conn)
		err = encoder.Encode(identifyMsg)
		if err != nil {
			conn.Close()
			return connectionErrorMsg{err}
		}

		return connectionSuccessMsg{conn}
	}
}

type connectionSuccessMsg struct {
	conn net.Conn
}

type connectionErrorMsg struct {
	err error
}

type agentResponseMsg struct {
	response message
}

func (m chatModel) listenForResponses() tea.Cmd {
	return func() tea.Msg {
		decoder := msgpack.NewDecoder(m.conn)
		var response message
		err := decoder.Decode(&response)
		if err != nil {
			return connectionErrorMsg{err}
		}
		return agentResponseMsg{response}
	}
}

func (m *chatModel) sendMessage(content string) tea.Cmd {
	return func() tea.Msg {
		m.messageID++
		msg := message{
			ID:   m.messageID,
			Type: "chat",
			Content: chatMessage{
				Type:    "user_message",
				Content: content,
			},
		}

		data, err := msgpack.Marshal(msg)
		if err != nil {
			return connectionErrorMsg{err}
		}

		_, err = m.conn.Write(data)
		if err != nil {
			return connectionErrorMsg{err}
		}

		return nil
	}
}

func (m chatModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyCtrlC:
			if m.connected && m.conn != nil {
				m.conn.Close()
			}
			return m, tea.Quit

		case tea.KeyCtrlS:
			// Send message
			if m.connected && strings.TrimSpace(m.textarea.Value()) != "" {
				userMsg := strings.TrimSpace(m.textarea.Value())
				m.messages = append(m.messages, userMessageStyle.Render("You: ")+userMsg)
				m.updateViewport()
				m.textarea.Reset()
				cmd := m.sendMessage(userMsg)
				cmds = append(cmds, cmd)
			}
		}

	case tea.WindowSizeMsg:
		if !m.ready {
			m.width = msg.Width
			m.height = msg.Height
			m.viewport.Width = msg.Width - 4
			m.viewport.Height = msg.Height - 8
			m.textarea.SetWidth(msg.Width - 4)
			m.ready = true
		}

	case connectionSuccessMsg:
		m.conn = msg.conn
		m.connected = true
		m.messages = append(m.messages, statusStyle.Render("✓ Connected to agent.nvim plugin"))
		m.updateViewport()
		cmds = append(cmds, m.listenForResponses())

	case connectionErrorMsg:
		m.connected = false
		m.err = msg.err
		m.messages = append(m.messages, errorStyle.Render("✗ Connection error: "+msg.err.Error()))
		m.updateViewport()
		// Try to reconnect after a delay
		cmds = append(cmds, tea.Tick(time.Second*5, func(t time.Time) tea.Msg {
			return m.connectToAgent()()
		}))

	case agentResponseMsg:
		// Handle response from agent
		m.handleAgentResponse(msg.response)
		m.updateViewport()
		// Continue listening for more responses
		cmds = append(cmds, m.listenForResponses())
	}

	// Update child components
	var cmd tea.Cmd
	m.textarea, cmd = m.textarea.Update(msg)
	cmds = append(cmds, cmd)

	m.viewport, cmd = m.viewport.Update(msg)
	cmds = append(cmds, cmd)

	return m, tea.Batch(cmds...)
}

func (m *chatModel) handleAgentResponse(response message) {
	switch response.Type {
	case "ack":
		// Acknowledgment from the service
		if contentMap, ok := response.Content.(map[string]interface{}); ok {
			if message, ok := contentMap["message"].(string); ok {
				m.messages = append(m.messages, statusStyle.Render("✓ "+message))
			}
		}
	case "message":
		if contentMap, ok := response.Content.(map[string]interface{}); ok {
			if content, ok := contentMap["content"].(string); ok {
				m.messages = append(m.messages, agentMessageStyle.Render("Agent: ")+content)
			}
		}
	case "notification":
		if contentMap, ok := response.Content.(map[string]interface{}); ok {
			if content, ok := contentMap["content"].(string); ok {
				m.messages = append(m.messages, messageStyle.Render("📢 "+content))
			}
		}
	case "edit":
		m.messages = append(m.messages, statusStyle.Render("✏️  Agent applied an edit to your code"))
	case "error":
		if contentMap, ok := response.Content.(map[string]interface{}); ok {
			if content, ok := contentMap["content"].(string); ok {
				m.messages = append(m.messages, errorStyle.Render("❌ Error: "+content))
			}
		}
	case "buffer", "selection":
		// Messages from neovim - display them as info
		m.messages = append(m.messages, statusStyle.Render("📝 Received code from Neovim"))
	case "status_response":
		// Display service status
		if data, err := json.MarshalIndent(response.Content, "", "  "); err == nil {
			m.messages = append(m.messages, messageStyle.Render("📊 Service Status:\n"+string(data)))
		}
	default:
		// Try to display as JSON for debugging
		if data, err := json.MarshalIndent(response, "", "  "); err == nil {
			m.messages = append(m.messages, messageStyle.Render("🔍 "+string(data)))
		}
	}
}

func (m *chatModel) updateViewport() {
	content := strings.Join(m.messages, "\n")
	m.viewport.SetContent(content)
	m.viewport.GotoBottom()
}

func (m chatModel) View() string {
	if !m.ready {
		return "Initializing..."
	}

	title := titleStyle.Render("Agent Chat Interface")

	var statusBar string
	if m.connected {
		statusBar = statusStyle.Render("🟢 Connected to agent.nvim")
	} else {
		statusBar = errorStyle.Render("🔴 Disconnected - attempting to reconnect...")
	}

	help := statusStyle.Render("Ctrl+S: Send message | Ctrl+C: Quit")

	content := lipgloss.JoinVertical(
		lipgloss.Left,
		title,
		statusBar,
		"",
		m.viewport.View(),
		"",
		m.textarea.View(),
		"",
		help,
	)

	return content
}

var chatCmd = &cobra.Command{
	Use:   "chat",
	Short: "Start the agent chat TUI",
	Long:  `Launch the terminal user interface for chatting with the agent and communicating with agent.nvim plugin.`,
	Run: func(cmd *cobra.Command, args []string) {
		log.Info("Starting agent chat interface...")

		p := tea.NewProgram(
			initialModel(),
			tea.WithAltScreen(),
			tea.WithMouseCellMotion(),
		)

		if _, err := p.Run(); err != nil {
			log.Fatal("Error running chat interface:", err)
		}
	},
}

func init() {
	rootCmd.AddCommand(chatCmd)
}
