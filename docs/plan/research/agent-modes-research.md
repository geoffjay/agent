# Agent Modes Research

## Overview

The agent system supports two distinct operational modes: **Autonomous** and **Chat**. Each mode has different behavioral patterns, interaction models, and implementation requirements. This research examines the design considerations and implementation approaches for both modes.

## Research Questions

1. **State Management**: How should agent state be managed differently between modes?
2. **Task Execution**: What are the execution patterns for autonomous vs interactive agents?
3. **User Interaction**: How do agents handle user input and feedback in each mode?
4. **Decision Making**: What decision-making frameworks are appropriate for each mode?
5. **Error Handling**: How should errors and failures be handled differently?
6. **Resource Management**: How do we manage computational resources across different modes?

## Mode Comparison Matrix

| Aspect | Autonomous Mode | Chat Mode |
|--------|----------------|-----------|
| **Trigger** | Task file or schedule | User message |
| **Execution** | Continuous/batch | Interactive/real-time |
| **State** | Persistent across tasks | Session-based |
| **User Interaction** | Minimal/notifications | High/conversational |
| **Decision Making** | Goal-oriented planning | Context-aware responses |
| **Error Handling** | Automatic retry/escalation | User-guided resolution |
| **Resource Usage** | Background/scheduled | On-demand/responsive |

## Autonomous Mode

### Overview
Autonomous agents operate independently to complete predefined tasks without constant human supervision. They are designed for batch processing, scheduled operations, and goal-oriented execution.

### Behavioral Characteristics

#### 1. Task-Driven Execution
```go
type AutonomousAgent struct {
    taskQueue   []Task
    planner     TaskPlanner
    executor    TaskExecutor
    monitor     ExecutionMonitor
    state       AgentState
}

func (a *AutonomousAgent) Run(ctx context.Context) error {
    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        default:
            task, err := a.getNextTask()
            if err != nil {
                continue
            }
            
            plan, err := a.planner.CreatePlan(task)
            if err != nil {
                a.handlePlanningError(task, err)
                continue
            }
            
            result := a.executor.Execute(ctx, plan)
            a.monitor.RecordResult(result)
            
            if result.RequiresHumanIntervention {
                a.escalateToHuman(task, result)
            }
        }
    }
}
```

#### 2. Goal-Oriented Planning
```go
type TaskPlanner interface {
    CreatePlan(task Task) (ExecutionPlan, error)
    AdaptPlan(plan ExecutionPlan, context PlanContext) (ExecutionPlan, error)
}

type ExecutionPlan struct {
    Steps       []PlanStep
    Dependencies []Dependency
    Resources   ResourceRequirements
    Constraints PlanConstraints
}

type PlanStep struct {
    ID          string
    Action      string
    Parameters  map[string]any
    Prerequisites []string
    EstimatedDuration time.Duration
}
```

#### 3. Self-Monitoring and Adaptation
```go
type ExecutionMonitor interface {
    RecordResult(result ExecutionResult)
    GetMetrics() AgentMetrics
    ShouldAdaptStrategy() bool
}

type AgentMetrics struct {
    TasksCompleted    int
    TasksFailed       int
    AverageExecutionTime time.Duration
    ResourceUtilization  ResourceMetrics
    ErrorRate         float64
}
```

### Implementation Patterns

#### 1. State Machine Architecture
```go
type AutonomousAgentState int

const (
    StateIdle AutonomousAgentState = iota
    StateTaskDiscovery
    StatePlanning
    StateExecuting
    StateMonitoring
    StateEscalating
    StateRecovering
)

func (a *AutonomousAgent) transition(newState AutonomousAgentState) {
    a.logStateTransition(a.state, newState)
    a.state = newState
    a.onStateEnter(newState)
}
```

#### 2. Task Discovery and Prioritization
```go
type TaskDiscovery interface {
    DiscoverTasks() ([]Task, error)
    PrioritizeTasks(tasks []Task) []Task
}

type PriorityTaskDiscovery struct {
    sources []TaskSource
    rules   []PriorityRule
}

func (d *PriorityTaskDiscovery) PrioritizeTasks(tasks []Task) []Task {
    sort.Slice(tasks, func(i, j int) bool {
        return d.calculatePriority(tasks[i]) > d.calculatePriority(tasks[j])
    })
    return tasks
}
```

#### 3. Resource Management

Resource management is **absolutely necessary** for a production AI agent system. Without proper resource management, agents can consume unlimited system resources, leading to system instability, poor performance, and potential security vulnerabilities.

##### Why Resource Management is Critical

**Problem 1: Runaway Resource Consumption**
AI agents, especially those using large language models, can consume enormous amounts of:
- **CPU**: Complex reasoning, code analysis, and decision-making processes
- **Memory**: Large context windows, conversation history, and intermediate computations  
- **Network**: API calls to LLM providers, external integrations, file downloads
- **Disk I/O**: File operations, log writing, temporary data storage

Without limits, a single autonomous agent could:
```go
// Example of problematic unbounded execution
func (a *AutonomousAgent) processLargeCodebase() {
    // This could consume GBs of memory and hours of CPU
    for _, file := range allFiles { // Could be 100,000+ files
        analysis := a.llm.AnalyzeCode(file) // Expensive LLM call
        a.cache[file] = analysis           // Unbounded memory growth
    }
}
```

**Problem 2: Resource Contention Between Agents**
Multiple agents running simultaneously can:
- Compete for limited system resources
- Cause system-wide performance degradation
- Lead to deadlocks or starvation scenarios
- Overwhelm external APIs with too many concurrent requests

**Problem 3: Cost Control**
AI agents make expensive API calls to LLM providers:
- Claude API: ~$3-15 per million tokens
- GPT-4: ~$10-30 per million tokens
- Without limits, costs can spiral out of control

**Problem 4: System Stability**
Uncontrolled resource usage can:
- Crash the host system due to memory exhaustion
- Make the system unresponsive to user interactions
- Interfere with other applications on the same machine

##### Resource Management Implementation

```go
type ResourceManager interface {
    AcquireResources(req ResourceRequirements) (ResourceAllocation, error)
    ReleaseResources(allocation ResourceAllocation) error
    GetAvailableResources() ResourceCapacity
    MonitorUsage() ResourceUsage
    EnforceLimits(allocation ResourceAllocation) error
}

type ResourceRequirements struct {
    CPU           float64              // CPU cores (0.5 = half core)
    Memory        int64                // Bytes
    MaxTokens     int                  // LLM API token limit
    MaxAPICalls   int                  // Rate limiting
    DiskSpace     int64                // Bytes for temporary storage
    NetworkBandwidth int64             // Bytes per second
    Duration      time.Duration        // Maximum execution time
}

type ResourceLimits struct {
    // Hard limits (cannot exceed)
    MaxMemoryMB       int     `yaml:"max_memory_mb"`
    MaxCPUCores       float64 `yaml:"max_cpu_cores"`
    MaxExecutionTime  string  `yaml:"max_execution_time"`
    
    // Soft limits (warnings/throttling)
    MemoryWarningMB   int     `yaml:"memory_warning_mb"`
    CPUThrottlePercent float64 `yaml:"cpu_throttle_percent"`
    
    // Cost controls
    MaxTokensPerHour  int     `yaml:"max_tokens_per_hour"`
    MaxAPICallsPerMin int     `yaml:"max_api_calls_per_minute"`
    DailyCostLimitUSD float64 `yaml:"daily_cost_limit_usd"`
}
```

##### Mode-Specific Resource Considerations

**Autonomous Mode Resource Challenges:**
```go
type AutonomousResourceManager struct {
    resourcePool    *ResourcePool
    taskQueue      *PriorityQueue
    costTracker    *CostTracker
    monitor        *ResourceMonitor
}

// Autonomous agents need resource reservations for long-running tasks
func (arm *AutonomousResourceManager) ScheduleTask(task Task) error {
    // Estimate resource requirements based on task complexity
    estimate := arm.estimateResourceNeeds(task)
    
    // Check if we have enough resources available
    if !arm.resourcePool.CanAllocate(estimate) {
        // Queue task for later or scale up resources
        return arm.queueTask(task, estimate)
    }
    
    // Reserve resources for the entire task duration
    allocation, err := arm.resourcePool.Reserve(estimate)
    if err != nil {
        return err
    }
    
    // Start monitoring resource usage
    monitor := arm.monitor.StartMonitoring(allocation)
    
    // Execute task with resource constraints
    return arm.executeWithLimits(task, allocation, monitor)
}
```

**Chat Mode Resource Challenges:**
```go
type ChatResourceManager struct {
    sessionPools   map[string]*SessionResourcePool
    responseCache  *LRUCache
    rateLimiter    *RateLimiter
}

// Chat agents need burst capacity and session isolation
func (crm *ChatResourceManager) HandleChatMessage(sessionID string, msg Message) error {
    // Get or create resource pool for this session
    pool := crm.getSessionPool(sessionID)
    
    // Apply rate limiting to prevent abuse
    if !crm.rateLimiter.Allow(sessionID) {
        return ErrRateLimitExceeded
    }
    
    // Check for cached responses to save resources
    if cached := crm.responseCache.Get(msg.Hash()); cached != nil {
        return crm.sendCachedResponse(cached)
    }
    
    // Allocate resources for response generation
    allocation := pool.AllocateForResponse(msg.EstimatedComplexity())
    
    // Generate response with resource monitoring
    return crm.generateResponse(msg, allocation)
}
```

##### Resource Monitoring and Alerting

```go
type ResourceMonitor struct {
    metrics    *MetricsCollector
    alerts     *AlertManager
    thresholds ResourceThresholds
}

func (rm *ResourceMonitor) MonitorAgent(agentID string, allocation ResourceAllocation) {
    ticker := time.NewTicker(time.Second)
    defer ticker.Stop()
    
    for {
        select {
        case <-ticker.C:
            usage := rm.getCurrentUsage(agentID)
            
            // Check for threshold violations
            if usage.Memory > allocation.Memory*0.9 {
                rm.alerts.Send(AlertHighMemoryUsage, agentID, usage)
            }
            
            if usage.TokensUsed > allocation.MaxTokens*0.8 {
                rm.alerts.Send(AlertTokenLimitApproaching, agentID, usage)
            }
            
            // Enforce hard limits
            if usage.Memory > allocation.Memory {
                rm.enforceMemoryLimit(agentID)
            }
            
            // Track costs
            rm.trackCosts(agentID, usage)
        }
    }
}
```

##### Real-World Resource Management Scenarios

**Scenario 1: Code Analysis Agent**
```yaml
# Resource configuration for a code analysis agent
agent_config:
  name: "code-analyzer:v1"
  resource_limits:
    max_memory_mb: 2048        # Analyzing large codebases
    max_cpu_cores: 1.0         # Single-threaded analysis
    max_execution_time: "30m"  # Prevent infinite loops
    max_tokens_per_hour: 50000 # Cost control for LLM calls
    max_files_per_run: 1000    # Prevent processing entire repos
```

**Scenario 2: Documentation Generator**
```yaml
# Resource configuration for documentation generation
agent_config:
  name: "doc-generator:v1"  
  resource_limits:
    max_memory_mb: 1024        # Moderate memory for processing
    max_cpu_cores: 0.5         # Background processing
    max_execution_time: "60m"  # Allow time for large docs
    max_tokens_per_hour: 100000 # Higher token limit for generation
    daily_cost_limit_usd: 10.0  # Budget control
```

**Scenario 3: Interactive Chat Assistant**
```yaml
# Resource configuration for chat mode
agent_config:
  name: "chat-assistant:v1"
  resource_limits:
    max_memory_mb: 512         # Lower memory for quick responses
    max_cpu_cores: 0.25        # Shared CPU for multiple sessions
    max_execution_time: "30s"  # Fast response requirement
    max_tokens_per_response: 2000 # Concise responses
    max_api_calls_per_minute: 10  # Rate limiting per user
```

##### Implementation Benefits

1. **System Stability**: Prevents resource exhaustion and crashes
2. **Cost Control**: Manages API usage and prevents runaway costs  
3. **Performance**: Ensures responsive system behavior
4. **Security**: Prevents resource-based denial of service attacks
5. **Scalability**: Enables running multiple agents safely
6. **Debugging**: Provides visibility into resource usage patterns

Resource management is not optional for a production AI agent system—it's a fundamental requirement for reliable, secure, and cost-effective operation.

### Error Handling and Recovery

#### 1. Automatic Retry Logic
```go
type RetryStrategy interface {
    ShouldRetry(attempt int, err error) bool
    GetBackoffDuration(attempt int) time.Duration
}

type ExponentialBackoffRetry struct {
    maxAttempts int
    baseDelay   time.Duration
    maxDelay    time.Duration
}

func (r *ExponentialBackoffRetry) ShouldRetry(attempt int, err error) bool {
    if attempt >= r.maxAttempts {
        return false
    }
    
    // Don't retry on certain error types
    if isUnrecoverableError(err) {
        return false
    }
    
    return true
}
```

#### 2. Escalation Mechanisms
```go
type EscalationHandler interface {
    EscalateToHuman(task Task, reason EscalationReason) error
    NotifyStakeholders(event AgentEvent) error
}

type EscalationReason int

const (
    EscalationTaskFailed EscalationReason = iota
    EscalationResourceUnavailable
    EscalationAmbiguousRequirements
    EscalationSecurityConcerns
)
```

## Chat Mode

### Overview
Chat agents provide interactive, conversational interfaces for users to accomplish tasks through natural language interaction. They are designed for real-time responsiveness and context-aware assistance.

### Behavioral Characteristics

#### 1. Conversational Flow Management
```go
type ChatAgent struct {
    conversation ConversationManager
    context      ChatContext
    responder    ResponseGenerator
    memory       ConversationMemory
}

func (c *ChatAgent) HandleMessage(ctx context.Context, message UserMessage) (AgentResponse, error) {
    // Update conversation context
    c.context.AddUserMessage(message)
    
    // Generate response based on context
    response, err := c.responder.GenerateResponse(ctx, c.context)
    if err != nil {
        return c.generateErrorResponse(err), nil
    }
    
    // Update conversation memory
    c.memory.Store(c.context.GetCurrentTurn())
    
    return response, nil
}
```

#### 2. Context-Aware Response Generation
```go
type ResponseGenerator interface {
    GenerateResponse(ctx context.Context, chatCtx ChatContext) (AgentResponse, error)
}

type ChatContext struct {
    SessionID     string
    User          User
    Messages      []Message
    CurrentTask   *Task
    Tools         []Tool
    Constraints   []Constraint
    History       ConversationHistory
}

type AgentResponse struct {
    Text         string
    Actions      []Action
    Attachments  []Attachment
    Suggestions  []Suggestion
    FollowUp     []FollowUpQuestion
}
```

#### 3. Real-time Interaction Patterns
```go
type InteractionPattern int

const (
    PatternQuestion InteractionPattern = iota
    PatternCommand
    PatternClarification
    PatternFeedback
    PatternMultiTurn
)

func (c *ChatAgent) identifyInteractionPattern(message UserMessage) InteractionPattern {
    // Use NLP/ML to classify interaction type
    // This helps determine appropriate response strategy
}
```

### Implementation Patterns

#### 1. Session Management

Session management requires persistent storage to maintain state across agent interactions and system restarts. To minimize external dependencies and simplify deployment, the system should use embedded database solutions.

##### Storage Technology Selection

**Embedded Database Requirements:**
- No external server dependencies
- Single-file or directory-based storage
- ACID compliance for data integrity
- Good performance for concurrent read/write operations
- Active maintenance and production readiness
- Go language support with mature drivers

**Recommended Technologies:**

**Primary Choice: SQLite**
```go
// SQLite-based session storage
type SQLiteSessionManager struct {
    db     *sql.DB
    dbPath string
}

func NewSQLiteSessionManager(dbPath string) (*SQLiteSessionManager, error) {
    db, err := sql.Open("sqlite3", dbPath+"?_foreign_keys=on&_journal_mode=WAL")
    if err != nil {
        return nil, err
    }
    
    // Enable WAL mode for better concurrent access
    if _, err := db.Exec("PRAGMA journal_mode=WAL;"); err != nil {
        return nil, err
    }
    
    // Create tables if they don't exist
    if err := createSessionTables(db); err != nil {
        return nil, err
    }
    
    return &SQLiteSessionManager{db: db, dbPath: dbPath}, nil
}

const createSessionsTable = `
CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    start_time DATETIME NOT NULL,
    last_activity DATETIME NOT NULL,
    state TEXT NOT NULL,
    context_data BLOB,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_last_activity ON sessions(last_activity);
`
```

**Alternative: BBolt (Key-Value Store)**
```go
// BBolt-based session storage for simpler key-value access patterns
type BoltSessionManager struct {
    db   *bbolt.DB
    path string
}

func NewBoltSessionManager(dbPath string) (*BoltSessionManager, error) {
    db, err := bbolt.Open(dbPath, 0600, &bbolt.Options{
        Timeout: 1 * time.Second,
    })
    if err != nil {
        return nil, err
    }
    
    // Create buckets for different data types
    err = db.Update(func(tx *bbolt.Tx) error {
        buckets := []string{"sessions", "conversations", "user_profiles"}
        for _, bucket := range buckets {
            if _, err := tx.CreateBucketIfNotExists([]byte(bucket)); err != nil {
                return err
            }
        }
        return nil
    })
    
    return &BoltSessionManager{db: db, path: dbPath}, nil
}

func (bsm *BoltSessionManager) CreateSession(userID string) (Session, error) {
    session := Session{
        ID:           generateSessionID(),
        UserID:       userID,
        StartTime:    time.Now(),
        LastActivity: time.Now(),
        State:        SessionStateActive,
    }
    
    return session, bsm.db.Update(func(tx *bbolt.Tx) error {
        bucket := tx.Bucket([]byte("sessions"))
        data, err := json.Marshal(session)
        if err != nil {
            return err
        }
        return bucket.Put([]byte(session.ID), data)
    })
}
```

**Technology Comparison:**

| Technology | Pros | Cons | Best For |
|------------|------|------|----------|
| **SQLite** | SQL queries, ACID, mature, excellent tooling | Larger file size, SQL overhead for simple KV | Complex queries, relations, reporting |
| **BBolt** | Very fast, small footprint, simple API | No SQL, manual indexing, Go-only | Simple KV operations, high performance |
| **Badger** | LSM-tree, high write throughput, transactions | More complex API, newer | High-write workloads, time-series data |

**Recommendation: SQLite** for the primary implementation due to:
- Mature ecosystem and tooling
- SQL flexibility for complex queries
- ACID compliance
- Wide adoption in production systems
- Excellent Go driver (github.com/mattn/go-sqlite3)

##### Session Management Implementation

```go
type SessionManager interface {
    CreateSession(userID string) (Session, error)
    GetSession(sessionID string) (Session, error)
    UpdateSession(session Session) error
    CloseSession(sessionID string) error
    GetActiveSessions(userID string) ([]Session, error)
    CleanupExpiredSessions(maxAge time.Duration) error
}

type Session struct {
    ID           string                 `json:"id" db:"id"`
    UserID       string                 `json:"user_id" db:"user_id"`
    StartTime    time.Time              `json:"start_time" db:"start_time"`
    LastActivity time.Time              `json:"last_activity" db:"last_activity"`
    Context      ChatContext            `json:"context" db:"context_data"`
    State        SessionState           `json:"state" db:"state"`
    Metadata     map[string]interface{} `json:"metadata" db:"metadata"`
}

type SessionState int

const (
    SessionStateActive SessionState = iota
    SessionStateIdle
    SessionStateClosed
    SessionStateExpired
)

// SQLite implementation with optimizations
func (sm *SQLiteSessionManager) CreateSession(userID string) (Session, error) {
    session := Session{
        ID:           generateUUIDv4(),
        UserID:       userID,
        StartTime:    time.Now(),
        LastActivity: time.Now(),
        State:        SessionStateActive,
        Context:      ChatContext{Messages: []Message{}},
        Metadata:     make(map[string]interface{}),
    }
    
    // Serialize context data
    contextData, err := json.Marshal(session.Context)
    if err != nil {
        return Session{}, err
    }
    
    query := `
        INSERT INTO sessions (id, user_id, start_time, last_activity, state, context_data, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    `
    
    _, err = sm.db.Exec(query, 
        session.ID, 
        session.UserID, 
        session.StartTime, 
        session.LastActivity, 
        int(session.State),
        contextData,
        "{}",
    )
    
    return session, err
}

func (sm *SQLiteSessionManager) GetSession(sessionID string) (Session, error) {
    var session Session
    var contextData []byte
    var stateInt int
    
    query := `
        SELECT id, user_id, start_time, last_activity, state, context_data 
        FROM sessions 
        WHERE id = ?
    `
    
    err := sm.db.QueryRow(query, sessionID).Scan(
        &session.ID,
        &session.UserID,
        &session.StartTime,
        &session.LastActivity,
        &stateInt,
        &contextData,
    )
    
    if err != nil {
        return Session{}, err
    }
    
    session.State = SessionState(stateInt)
    
    // Deserialize context data
    if err := json.Unmarshal(contextData, &session.Context); err != nil {
        return Session{}, err
    }
    
    return session, nil
}

func (sm *SQLiteSessionManager) CleanupExpiredSessions(maxAge time.Duration) error {
    expiredBefore := time.Now().Add(-maxAge)
    
    query := `
        DELETE FROM sessions 
        WHERE last_activity < ? AND state != ?
    `
    
    _, err := sm.db.Exec(query, expiredBefore, int(SessionStateActive))
    return err
}
```

##### Session Storage Optimization

**Performance Considerations:**
```go
// Connection pool for concurrent access
type OptimizedSQLiteManager struct {
    db *sql.DB
    sessionCache *lru.Cache
}

func NewOptimizedSQLiteManager(dbPath string, cacheSize int) (*OptimizedSQLiteManager, error) {
    db, err := sql.Open("sqlite3", dbPath+"?_busy_timeout=5000&_journal_mode=WAL&_synchronous=NORMAL")
    if err != nil {
        return nil, err
    }
    
    // Configure connection pool
    db.SetMaxOpenConns(10)
    db.SetMaxIdleConns(5)
    db.SetConnMaxLifetime(time.Hour)
    
    // Create LRU cache for frequently accessed sessions
    cache, err := lru.New(cacheSize)
    if err != nil {
        return nil, err
    }
    
    return &OptimizedSQLiteManager{
        db: db,
        sessionCache: cache,
    }, nil
}

func (osm *OptimizedSQLiteManager) GetSession(sessionID string) (Session, error) {
    // Check cache first
    if cached, ok := osm.sessionCache.Get(sessionID); ok {
        return cached.(Session), nil
    }
    
    // Fallback to database
    session, err := osm.getSessionFromDB(sessionID)
    if err != nil {
        return Session{}, err
    }
    
    // Cache the result
    osm.sessionCache.Add(sessionID, session)
    
    return session, nil
}
```

##### Database Schema Design

**Complete SQLite Schema:**
```sql
-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    start_time DATETIME NOT NULL,
    last_activity DATETIME NOT NULL,
    state INTEGER NOT NULL DEFAULT 0,
    context_data BLOB,
    metadata TEXT DEFAULT '{}',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Conversations table (for detailed conversation history)
CREATE TABLE IF NOT EXISTS conversations (
    id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    started_at DATETIME NOT NULL,
    ended_at DATETIME,
    turn_count INTEGER DEFAULT 0,
    summary TEXT,
    topic_tags TEXT DEFAULT '[]',
    total_tokens INTEGER DEFAULT 0,
    satisfaction_score REAL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Conversation turns table
CREATE TABLE IF NOT EXISTS conversation_turns (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL,
    turn_number INTEGER NOT NULL,
    user_message TEXT NOT NULL,
    agent_response TEXT NOT NULL,
    timestamp DATETIME NOT NULL,
    processing_time_ms INTEGER,
    context_data BLOB,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
);

-- User profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
    user_id TEXT PRIMARY KEY,
    preferences TEXT DEFAULT '{}',
    communication_style TEXT,
    trusted_tools TEXT DEFAULT '[]',
    common_tasks TEXT DEFAULT '[]',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_last_activity ON sessions(last_activity);
CREATE INDEX IF NOT EXISTS idx_sessions_state ON sessions(state);
CREATE INDEX IF NOT EXISTS idx_conversations_session_id ON conversations(session_id);
CREATE INDEX IF NOT EXISTS idx_conversations_user_id ON conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_turns_conversation_id ON conversation_turns(conversation_id);
CREATE INDEX IF NOT EXISTS idx_turns_timestamp ON conversation_turns(timestamp);

-- Triggers for automatic timestamp updates
CREATE TRIGGER IF NOT EXISTS update_sessions_timestamp 
    AFTER UPDATE ON sessions
    BEGIN
        UPDATE sessions SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
    END;

CREATE TRIGGER IF NOT EXISTS update_profiles_timestamp 
    AFTER UPDATE ON user_profiles
    BEGIN
        UPDATE user_profiles SET updated_at = CURRENT_TIMESTAMP WHERE user_id = NEW.user_id;
    END;
```

#### 2. Multi-Turn Conversation Handling

Multi-turn conversations require efficient storage and retrieval of conversation history, with consideration for context window management and performance optimization.

```go
type ConversationManager interface {
    StartConversation(userID string) (ConversationID, error)
    AddTurn(convID ConversationID, turn ConversationTurn) error
    GetConversationHistory(convID ConversationID, limit int) ([]ConversationTurn, error)
    GetRecentContext(convID ConversationID, maxTokens int) (ChatContext, error)
    EndConversation(convID ConversationID) error
    ArchiveOldConversations(olderThan time.Time) error
}

type ConversationTurn struct {
    ID               string                 `json:"id" db:"id"`
    ConversationID   string                 `json:"conversation_id" db:"conversation_id"`
    TurnNumber       int                    `json:"turn_number" db:"turn_number"`
    UserMessage      UserMessage            `json:"user_message" db:"user_message"`
    AgentResponse    AgentResponse          `json:"agent_response" db:"agent_response"`
    Timestamp        time.Time              `json:"timestamp" db:"timestamp"`
    ProcessingTimeMs int                    `json:"processing_time_ms" db:"processing_time_ms"`
    Context          TurnContext            `json:"context" db:"context_data"`
    TokensUsed       int                    `json:"tokens_used" db:"tokens_used"`
}

// SQLite-based conversation management with optimization for context retrieval
type SQLiteConversationManager struct {
    db           *sql.DB
    tokenCounter TokenCounter
    contextCache *lru.Cache
}

func (cm *SQLiteConversationManager) AddTurn(convID ConversationID, turn ConversationTurn) error {
    // Calculate token usage for context management
    tokens := cm.tokenCounter.CountTokens(turn.UserMessage.Text + turn.AgentResponse.Text)
    turn.TokensUsed = tokens
    
    tx, err := cm.db.Begin()
    if err != nil {
        return err
    }
    defer tx.Rollback()
    
    // Insert the turn
    query := `
        INSERT INTO conversation_turns 
        (id, conversation_id, turn_number, user_message, agent_response, timestamp, processing_time_ms, context_data, tokens_used)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `
    
    userMsgJSON, _ := json.Marshal(turn.UserMessage)
    agentRespJSON, _ := json.Marshal(turn.AgentResponse)
    contextJSON, _ := json.Marshal(turn.Context)
    
    _, err = tx.Exec(query,
        turn.ID,
        turn.ConversationID,
        turn.TurnNumber,
        string(userMsgJSON),
        string(agentRespJSON),
        turn.Timestamp,
        turn.ProcessingTimeMs,
        contextJSON,
        turn.TokensUsed,
    )
    if err != nil {
        return err
    }
    
    // Update conversation metadata
    updateQuery := `
        UPDATE conversations 
        SET turn_count = turn_count + 1, ended_at = ? 
        WHERE id = ?
    `
    _, err = tx.Exec(updateQuery, turn.Timestamp, turn.ConversationID)
    if err != nil {
        return err
    }
    
    // Invalidate cache for this conversation
    cm.contextCache.Remove(string(convID))
    
    return tx.Commit()
}

func (cm *SQLiteConversationManager) GetRecentContext(convID ConversationID, maxTokens int) (ChatContext, error) {
    // Check cache first
    if cached, ok := cm.contextCache.Get(string(convID)); ok {
        return cached.(ChatContext), nil
    }
    
    // Retrieve turns in reverse order and build context within token limit
    query := `
        SELECT user_message, agent_response, tokens_used, timestamp
        FROM conversation_turns 
        WHERE conversation_id = ? 
        ORDER BY turn_number DESC
    `
    
    rows, err := cm.db.Query(query, convID)
    if err != nil {
        return ChatContext{}, err
    }
    defer rows.Close()
    
    var context ChatContext
    totalTokens := 0
    
    for rows.Next() {
        var userMsgJSON, agentRespJSON string
        var tokensUsed int
        var timestamp time.Time
        
        err := rows.Scan(&userMsgJSON, &agentRespJSON, &tokensUsed, &timestamp)
        if err != nil {
            continue
        }
        
        if totalTokens+tokensUsed > maxTokens {
            break // Stop adding turns if we exceed token limit
        }
        
        var userMsg UserMessage
        var agentResp AgentResponse
        
        json.Unmarshal([]byte(userMsgJSON), &userMsg)
        json.Unmarshal([]byte(agentRespJSON), &agentResp)
        
        // Prepend to maintain chronological order
        context.Messages = append([]Message{
            {Role: "user", Content: userMsg.Text, Timestamp: timestamp},
            {Role: "assistant", Content: agentResp.Text, Timestamp: timestamp},
        }, context.Messages...)
        
        totalTokens += tokensUsed
    }
    
    // Cache the result
    cm.contextCache.Add(string(convID), context)
    
    return context, nil
}
```

#### 3. Tool Integration for Chat

Tool execution results and history need persistent storage for caching and audit purposes.

```go
type ChatTool interface {
    Name() string
    Description() string
    Execute(ctx context.Context, params ToolParameters) (ToolResult, error)
    GetSchema() ToolSchema
    IsCacheable() bool
}

type ToolExecutionCache interface {
    GetCachedResult(toolName string, params ToolParameters) (ToolResult, bool)
    CacheResult(toolName string, params ToolParameters, result ToolResult, ttl time.Duration) error
    InvalidateCache(toolName string) error
}

// SQLite-based tool cache with TTL support
type SQLiteToolCache struct {
    db *sql.DB
}

func (tc *SQLiteToolCache) GetCachedResult(toolName string, params ToolParameters) (ToolResult, bool) {
    paramHash := tc.hashParameters(params)
    
    query := `
        SELECT result_data, created_at, ttl_seconds
        FROM tool_cache 
        WHERE tool_name = ? AND param_hash = ? AND datetime('now') < datetime(created_at, '+' || ttl_seconds || ' seconds')
    `
    
    var resultJSON string
    var createdAt time.Time
    var ttlSeconds int
    
    err := tc.db.QueryRow(query, toolName, paramHash).Scan(&resultJSON, &createdAt, &ttlSeconds)
    if err != nil {
        return ToolResult{}, false
    }
    
    var result ToolResult
    if err := json.Unmarshal([]byte(resultJSON), &result); err != nil {
        return ToolResult{}, false
    }
    
    return result, true
}

func (tc *SQLiteToolCache) CacheResult(toolName string, params ToolParameters, result ToolResult, ttl time.Duration) error {
    paramHash := tc.hashParameters(params)
    resultJSON, _ := json.Marshal(result)
    
    query := `
        INSERT OR REPLACE INTO tool_cache (tool_name, param_hash, parameters, result_data, ttl_seconds, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    `
    
    _, err := tc.db.Exec(query,
        toolName,
        paramHash,
        tc.parametersToJSON(params),
        string(resultJSON),
        int(ttl.Seconds()),
        time.Now(),
    )
    
    return err
}

// Tool cache schema
const createToolCacheTable = `
CREATE TABLE IF NOT EXISTS tool_cache (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tool_name TEXT NOT NULL,
    param_hash TEXT NOT NULL,
    parameters TEXT NOT NULL,
    result_data BLOB NOT NULL,
    ttl_seconds INTEGER NOT NULL,
    created_at DATETIME NOT NULL,
    UNIQUE(tool_name, param_hash)
);

CREATE INDEX IF NOT EXISTS idx_tool_cache_lookup ON tool_cache(tool_name, param_hash);
CREATE INDEX IF NOT EXISTS idx_tool_cache_expiry ON tool_cache(created_at, ttl_seconds);
`

func (c *ChatAgent) invokeTool(invocation ToolInvocation) (ToolResult, error) {
    // Check cache for cacheable tools
    if invocation.Tool.IsCacheable() {
        if cached, found := c.toolCache.GetCachedResult(invocation.Tool.Name(), invocation.Parameters); found {
            return cached, nil
        }
    }
    
    // Validate parameters against schema
    if err := invocation.Tool.GetSchema().Validate(invocation.Parameters); err != nil {
        return ToolResult{}, err
    }
    
    // Execute tool with timeout
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()
    
    result, err := invocation.Tool.Execute(ctx, invocation.Parameters)
    if err != nil {
        return result, err
    }
    
    // Cache successful results
    if invocation.Tool.IsCacheable() && err == nil {
        c.toolCache.CacheResult(invocation.Tool.Name(), invocation.Parameters, result, 5*time.Minute)
    }
    
    return result, nil
}
```

### Memory and Context Management

Memory management requires both in-memory and persistent storage solutions to handle different retention requirements and performance needs.

#### 1. Short-term Memory (Session Context)

Short-term memory should use a hybrid approach: in-memory for active sessions with database persistence for recovery.

```go
type HybridShortTermMemory struct {
    inMemoryCache map[string]*SessionMemory
    database      *sql.DB
    mutex         sync.RWMutex
    maxCacheSize  int
}

type SessionMemory struct {
    SessionID       string              `json:"session_id"`
    RecentMessages  []Message           `json:"recent_messages"`
    CurrentTask     *Task               `json:"current_task"`
    UserPreferences map[string]any      `json:"user_preferences"`
    SessionGoals    []Goal              `json:"session_goals"`
    LastAccessed    time.Time           `json:"last_accessed"`
    ContextTokens   int                 `json:"context_tokens"`
}

func NewHybridShortTermMemory(dbPath string, maxCacheSize int) (*HybridShortTermMemory, error) {
    db, err := sql.Open("sqlite3", dbPath)
    if err != nil {
        return nil, err
    }
    
    // Create memory tables
    if err := createMemoryTables(db); err != nil {
        return nil, err
    }
    
    return &HybridShortTermMemory{
        inMemoryCache: make(map[string]*SessionMemory),
        database:      db,
        maxCacheSize:  maxCacheSize,
    }, nil
}

func (hsm *HybridShortTermMemory) GetSessionMemory(sessionID string) (*SessionMemory, error) {
    hsm.mutex.RLock()
    if memory, exists := hsm.inMemoryCache[sessionID]; exists {
        memory.LastAccessed = time.Now()
        hsm.mutex.RUnlock()
        return memory, nil
    }
    hsm.mutex.RUnlock()
    
    // Load from database
    memory, err := hsm.loadFromDatabase(sessionID)
    if err != nil {
        // Create new session memory
        memory = &SessionMemory{
            SessionID:       sessionID,
            RecentMessages:  []Message{},
            UserPreferences: make(map[string]any),
            SessionGoals:    []Goal{},
            LastAccessed:    time.Now(),
        }
    }
    
    // Add to cache (with eviction if needed)
    hsm.mutex.Lock()
    if len(hsm.inMemoryCache) >= hsm.maxCacheSize {
        hsm.evictLeastRecentlyUsed()
    }
    hsm.inMemoryCache[sessionID] = memory
    hsm.mutex.Unlock()
    
    return memory, nil
}

func (hsm *HybridShortTermMemory) AddMessage(sessionID string, msg Message) error {
    memory, err := hsm.GetSessionMemory(sessionID)
    if err != nil {
        return err
    }
    
    // Add message with sliding window
    memory.RecentMessages = append(memory.RecentMessages, msg)
    if len(memory.RecentMessages) > 20 { // Keep last 20 messages
        memory.RecentMessages = memory.RecentMessages[1:]
    }
    
    // Update token count
    memory.ContextTokens = hsm.calculateTokens(memory.RecentMessages)
    
    // Persist to database periodically
    return hsm.PersistSessionMemory(sessionID)
}

func (hsm *HybridShortTermMemory) PersistSessionMemory(sessionID string) error {
    hsm.mutex.RLock()
    memory, exists := hsm.inMemoryCache[sessionID]
    hsm.mutex.RUnlock()
    
    if !exists {
        return fmt.Errorf("session memory not found: %s", sessionID)
    }
    
    return hsm.saveToDatabase(memory)
}

const createMemoryTables = `
CREATE TABLE IF NOT EXISTS session_memory (
    session_id TEXT PRIMARY KEY,
    recent_messages BLOB,
    current_task BLOB,
    user_preferences TEXT,
    session_goals BLOB,
    context_tokens INTEGER,
    last_accessed DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_memory_last_accessed ON session_memory(last_accessed);
`
```

#### 2. Long-term Memory (User History)

Long-term memory requires robust persistence with efficient querying capabilities for user preferences and historical context.

```go
type SQLiteLongTermMemory struct {
    db           *sql.DB
    searchIndex  *SearchIndex // For semantic search over conversation history
    analytics    *UserAnalytics
}

type UserAnalytics struct {
    UserID              string                 `json:"user_id"`
    TotalConversations  int                    `json:"total_conversations"`
    TotalTokensUsed     int                    `json:"total_tokens_used"`
    MostUsedTools       []ToolUsageStats       `json:"most_used_tools"`
    PreferredTopics     []TopicFrequency       `json:"preferred_topics"`
    CommunicationStyle  CommunicationProfile   `json:"communication_style"`
    LastActive          time.Time              `json:"last_active"`
}

type UserProfile struct {
    UserID             string                 `json:"user_id"`
    Preferences        map[string]any         `json:"preferences"`
    CommonTasks        []TaskTemplate         `json:"common_tasks"`
    TrustedTools       []string               `json:"trusted_tools"`
    CommunicationStyle CommunicationProfile   `json:"communication_style"`
    CreatedAt          time.Time              `json:"created_at"`
    UpdatedAt          time.Time              `json:"updated_at"`
}

func (ltm *SQLiteLongTermMemory) StoreConversation(conv Conversation) error {
    tx, err := ltm.db.Begin()
    if err != nil {
        return err
    }
    defer tx.Rollback()
    
    // Store conversation metadata
    convQuery := `
        INSERT INTO conversations (id, session_id, user_id, started_at, ended_at, turn_count, summary, topic_tags, total_tokens)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `
    
    topicTags, _ := json.Marshal(ltm.extractTopics(conv))
    summary := ltm.generateSummary(conv)
    
    _, err = tx.Exec(convQuery,
        conv.ID,
        conv.SessionID,
        conv.UserID,
        conv.StartedAt,
        conv.EndedAt,
        conv.TurnCount,
        summary,
        string(topicTags),
        conv.TotalTokens,
    )
    if err != nil {
        return err
    }
    
    // Update user analytics
    if err := ltm.updateUserAnalytics(tx, conv); err != nil {
        return err
    }
    
    // Index for semantic search
    if err := ltm.searchIndex.IndexConversation(conv); err != nil {
        return err
    }
    
    return tx.Commit()
}

func (ltm *SQLiteLongTermMemory) GetUserPreferences(userID string) (UserProfile, error) {
    var profile UserProfile
    var prefsJSON, tasksJSON, toolsJSON string
    
    query := `
        SELECT user_id, preferences, communication_style, trusted_tools, common_tasks, created_at, updated_at
        FROM user_profiles 
        WHERE user_id = ?
    `
    
    err := ltm.db.QueryRow(query, userID).Scan(
        &profile.UserID,
        &prefsJSON,
        &profile.CommunicationStyle,
        &toolsJSON,
        &tasksJSON,
        &profile.CreatedAt,
        &profile.UpdatedAt,
    )
    
    if err != nil {
        return UserProfile{}, err
    }
    
    // Deserialize JSON fields
    json.Unmarshal([]byte(prefsJSON), &profile.Preferences)
    json.Unmarshal([]byte(toolsJSON), &profile.TrustedTools)
    json.Unmarshal([]byte(tasksJSON), &profile.CommonTasks)
    
    return profile, nil
}

func (ltm *SQLiteLongTermMemory) UpdateUserProfile(userID string, profile UserProfile) error {
    prefsJSON, _ := json.Marshal(profile.Preferences)
    toolsJSON, _ := json.Marshal(profile.TrustedTools)
    tasksJSON, _ := json.Marshal(profile.CommonTasks)
    
    query := `
        INSERT OR REPLACE INTO user_profiles 
        (user_id, preferences, communication_style, trusted_tools, common_tasks, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
    `
    
    _, err := ltm.db.Exec(query,
        userID,
        string(prefsJSON),
        profile.CommunicationStyle,
        string(toolsJSON),
        string(tasksJSON),
        time.Now(),
    )
    
    return err
}

func (ltm *SQLiteLongTermMemory) GetConversationsByTopic(userID string, topic string, limit int) ([]Conversation, error) {
    query := `
        SELECT id, session_id, started_at, ended_at, turn_count, summary, total_tokens
        FROM conversations 
        WHERE user_id = ? AND topic_tags LIKE ?
        ORDER BY started_at DESC
        LIMIT ?
    `
    
    rows, err := ltm.db.Query(query, userID, "%"+topic+"%", limit)
    if err != nil {
        return nil, err
    }
    defer rows.Close()
    
    var conversations []Conversation
    for rows.Next() {
        var conv Conversation
        err := rows.Scan(
            &conv.ID,
            &conv.SessionID,
            &conv.StartedAt,
            &conv.EndedAt,
            &conv.TurnCount,
            &conv.Summary,
            &conv.TotalTokens,
        )
        if err != nil {
            continue
        }
        conversations = append(conversations, conv)
    }
    
    return conversations, nil
}

// Enhanced schema for long-term memory
const createLongTermMemoryTables = `
-- Enhanced conversations table with analytics
CREATE TABLE IF NOT EXISTS conversations (
    id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    started_at DATETIME NOT NULL,
    ended_at DATETIME,
    turn_count INTEGER DEFAULT 0,
    summary TEXT,
    topic_tags TEXT DEFAULT '[]',
    total_tokens INTEGER DEFAULT 0,
    satisfaction_score REAL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
);

-- User analytics table
CREATE TABLE IF NOT EXISTS user_analytics (
    user_id TEXT PRIMARY KEY,
    total_conversations INTEGER DEFAULT 0,
    total_tokens_used INTEGER DEFAULT 0,
    avg_conversation_length REAL DEFAULT 0,
    most_used_tools TEXT DEFAULT '[]',
    preferred_topics TEXT DEFAULT '[]',
    communication_style TEXT,
    last_active DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tool usage tracking
CREATE TABLE IF NOT EXISTS tool_usage_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    tool_name TEXT NOT NULL,
    usage_count INTEGER DEFAULT 1,
    last_used DATETIME NOT NULL,
    success_rate REAL DEFAULT 1.0,
    avg_execution_time_ms INTEGER
);

-- Performance indexes for analytics
CREATE INDEX IF NOT EXISTS idx_conversations_user_topic ON conversations(user_id, topic_tags);
CREATE INDEX IF NOT EXISTS idx_conversations_started_at ON conversations(started_at);
CREATE INDEX IF NOT EXISTS idx_tool_usage_user_tool ON tool_usage_history(user_id, tool_name);
CREATE INDEX IF NOT EXISTS idx_analytics_last_active ON user_analytics(last_active);
`
```

#### 3. Autonomous Agent State Persistence

Autonomous agents need persistent state management for task queues, execution history, and recovery from failures or restarts.

```go
type AutonomousAgentStateManager struct {
    db         *sql.DB
    agentID    string
    stateCache map[string]interface{}
    mutex      sync.RWMutex
}

type AgentState struct {
    AgentID         string                 `json:"agent_id" db:"agent_id"`
    CurrentState    AutonomousAgentState   `json:"current_state" db:"current_state"`
    TaskQueue       []Task                 `json:"task_queue" db:"task_queue"`
    ActiveTasks     []Task                 `json:"active_tasks" db:"active_tasks"`
    CompletedTasks  []TaskResult           `json:"completed_tasks" db:"completed_tasks"`
    LastCheckpoint  time.Time              `json:"last_checkpoint" db:"last_checkpoint"`
    ExecutionStats  AgentExecutionStats    `json:"execution_stats" db:"execution_stats"`
    Configuration   AgentConfig            `json:"configuration" db:"configuration"`
    ErrorHistory    []AgentError           `json:"error_history" db:"error_history"`
}

type AgentExecutionStats struct {
    TasksCompleted      int           `json:"tasks_completed"`
    TasksFailed         int           `json:"tasks_failed"`
    TotalExecutionTime  time.Duration `json:"total_execution_time"`
    AverageTaskTime     time.Duration `json:"average_task_time"`
    LastSuccess         time.Time     `json:"last_success"`
    ConsecutiveFailures int           `json:"consecutive_failures"`
}

func (asm *AutonomousAgentStateManager) SaveCheckpoint(state AgentState) error {
    state.LastCheckpoint = time.Now()
    
    // Serialize complex fields
    taskQueueJSON, _ := json.Marshal(state.TaskQueue)
    activeTasksJSON, _ := json.Marshal(state.ActiveTasks)
    completedTasksJSON, _ := json.Marshal(state.CompletedTasks)
    statsJSON, _ := json.Marshal(state.ExecutionStats)
    configJSON, _ := json.Marshal(state.Configuration)
    errorHistoryJSON, _ := json.Marshal(state.ErrorHistory)
    
    query := `
        INSERT OR REPLACE INTO agent_state 
        (agent_id, current_state, task_queue, active_tasks, completed_tasks, execution_stats, configuration, error_history, last_checkpoint)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `
    
    _, err := asm.db.Exec(query,
        state.AgentID,
        int(state.CurrentState),
        string(taskQueueJSON),
        string(activeTasksJSON),
        string(completedTasksJSON),
        string(statsJSON),
        string(configJSON),
        string(errorHistoryJSON),
        state.LastCheckpoint,
    )
    
    return err
}

func (asm *AutonomousAgentStateManager) RestoreState() (AgentState, error) {
    var state AgentState
    var currentStateInt int
    var taskQueueJSON, activeTasksJSON, completedTasksJSON, statsJSON, configJSON, errorHistoryJSON string
    
    query := `
        SELECT agent_id, current_state, task_queue, active_tasks, completed_tasks, execution_stats, configuration, error_history, last_checkpoint
        FROM agent_state 
        WHERE agent_id = ?
    `
    
    err := asm.db.QueryRow(query, asm.agentID).Scan(
        &state.AgentID,
        &currentStateInt,
        &taskQueueJSON,
        &activeTasksJSON,
        &completedTasksJSON,
        &statsJSON,
        &configJSON,
        &errorHistoryJSON,
        &state.LastCheckpoint,
    )
    
    if err != nil {
        return AgentState{}, err
    }
    
    state.CurrentState = AutonomousAgentState(currentStateInt)
    
    // Deserialize complex fields
    json.Unmarshal([]byte(taskQueueJSON), &state.TaskQueue)
    json.Unmarshal([]byte(activeTasksJSON), &state.ActiveTasks)
    json.Unmarshal([]byte(completedTasksJSON), &state.CompletedTasks)
    json.Unmarshal([]byte(statsJSON), &state.ExecutionStats)
    json.Unmarshal([]byte(configJSON), &state.Configuration)
    json.Unmarshal([]byte(errorHistoryJSON), &state.ErrorHistory)
    
    return state, nil
}

func (asm *AutonomousAgentStateManager) RecordTaskCompletion(taskID string, result TaskResult) error {
    // Update execution statistics
    updateStatsQuery := `
        UPDATE agent_state 
        SET execution_stats = json_set(execution_stats, '$.tasks_completed', json_extract(execution_stats, '$.tasks_completed') + 1),
            execution_stats = json_set(execution_stats, '$.last_success', ?),
            execution_stats = json_set(execution_stats, '$.consecutive_failures', 0)
        WHERE agent_id = ?
    `
    
    _, err := asm.db.Exec(updateStatsQuery, time.Now(), asm.agentID)
    if err != nil {
        return err
    }
    
    // Record detailed task result
    insertResultQuery := `
        INSERT INTO task_execution_history 
        (agent_id, task_id, task_type, start_time, end_time, status, result_data, error_message)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `
    
    resultJSON, _ := json.Marshal(result)
    
    _, err = asm.db.Exec(insertResultQuery,
        asm.agentID,
        taskID,
        result.TaskType,
        result.StartTime,
        result.EndTime,
        result.Status,
        string(resultJSON),
        result.ErrorMessage,
    )
    
    return err
}

// Autonomous agent state schema
const createAgentStateTables = `
CREATE TABLE IF NOT EXISTS agent_state (
    agent_id TEXT PRIMARY KEY,
    current_state INTEGER NOT NULL,
    task_queue BLOB,
    active_tasks BLOB,
    completed_tasks BLOB,
    execution_stats BLOB,
    configuration BLOB,
    error_history BLOB,
    last_checkpoint DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS task_execution_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT NOT NULL,
    task_id TEXT NOT NULL,
    task_type TEXT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    status TEXT NOT NULL,
    result_data BLOB,
    error_message TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (agent_id) REFERENCES agent_state(agent_id)
);

CREATE INDEX IF NOT EXISTS idx_agent_state_checkpoint ON agent_state(last_checkpoint);
CREATE INDEX IF NOT EXISTS idx_task_history_agent ON task_execution_history(agent_id, start_time);
CREATE INDEX IF NOT EXISTS idx_task_history_status ON task_execution_history(status, start_time);
`
```

### Storage Configuration and Management

#### Database Initialization and Migration

```go
type DatabaseManager struct {
    dbPath   string
    db       *sql.DB
    migrator *Migrator
    config   *DatabaseConfig
}

type DatabaseConfig struct {
    Path                string        `yaml:"path" json:"path"`
    MaxConnections      int           `yaml:"max_connections" json:"max_connections"`
    ConnectionTimeout   time.Duration `yaml:"connection_timeout" json:"connection_timeout"`
    QueryTimeout        time.Duration `yaml:"query_timeout" json:"query_timeout"`
    BackupInterval      time.Duration `yaml:"backup_interval" json:"backup_interval"`
    CleanupInterval     time.Duration `yaml:"cleanup_interval" json:"cleanup_interval"`
    MaxDatabaseSizeMB   int64         `yaml:"max_database_size_mb" json:"max_database_size_mb"`
    VacuumInterval      time.Duration `yaml:"vacuum_interval" json:"vacuum_interval"`
}

func NewDatabaseManager(config *DatabaseConfig) (*DatabaseManager, error) {
    // Ensure database directory exists
    if err := os.MkdirAll(filepath.Dir(config.Path), 0755); err != nil {
        return nil, err
    }
    
    db, err := sql.Open("sqlite3", config.Path+"?_foreign_keys=on&_journal_mode=WAL")
    if err != nil {
        return nil, err
    }
    
    // Configure SQLite for optimal performance
    pragmas := []string{
        "PRAGMA journal_mode=WAL",
        "PRAGMA synchronous=NORMAL",
        "PRAGMA cache_size=10000",
        "PRAGMA temp_store=memory",
        "PRAGMA mmap_size=268435456", // 256MB
        fmt.Sprintf("PRAGMA busy_timeout=%d", int(config.ConnectionTimeout.Milliseconds())),
    }
    
    for _, pragma := range pragmas {
        if _, err := db.Exec(pragma); err != nil {
            return nil, fmt.Errorf("failed to set pragma %s: %w", pragma, err)
        }
    }
    
    // Configure connection pool
    db.SetMaxOpenConns(config.MaxConnections)
    db.SetMaxIdleConns(config.MaxConnections / 2)
    db.SetConnMaxLifetime(time.Hour)
    
    migrator := NewMigrator(db, config)
    
    dm := &DatabaseManager{
        dbPath:   config.Path,
        db:       db,
        migrator: migrator,
        config:   config,
    }
    
    // Start background maintenance
    go dm.startMaintenanceRoutines()
    
    return dm, nil
}

func (dm *DatabaseManager) Initialize() error {
    return dm.migrator.RunMigrations()
}

func (dm *DatabaseManager) Backup(backupPath string) error {
    return dm.migrator.CreateBackup(backupPath)
}

func (dm *DatabaseManager) GetHealthStatus() DatabaseHealthStatus {
    var status DatabaseHealthStatus
    
    // Check database connection
    if err := dm.db.Ping(); err != nil {
        status.Status = "unhealthy"
        status.Error = err.Error()
        return status
    }
    
    // Check database size and performance
    var dbSize int64
    var pageCount, pageSize int64
    dm.db.QueryRow("SELECT page_count, page_size FROM pragma_page_count(), pragma_page_size()").Scan(&pageCount, &pageSize)
    dbSize = pageCount * pageSize
    
    // Check WAL file size
    var walSize int64
    if stat, err := os.Stat(dm.dbPath + "-wal"); err == nil {
        walSize = stat.Size()
    }
    
    // Performance metrics
    var fragmentationRatio float64
    dm.db.QueryRow("SELECT freelist_count * 100.0 / page_count FROM pragma_freelist_count(), pragma_page_count()").Scan(&fragmentationRatio)
    
    status.Status = "healthy"
    status.DatabaseSize = dbSize
    status.WALSize = walSize
    status.FragmentationRatio = fragmentationRatio
    status.CheckTime = time.Now()
    
    // Health warnings
    if dbSize > dm.config.MaxDatabaseSizeMB*1024*1024 {
        status.Warnings = append(status.Warnings, "Database size exceeds configured limit")
    }
    
    if fragmentationRatio > 20.0 {
        status.Warnings = append(status.Warnings, "High database fragmentation detected")
    }
    
    if walSize > dbSize/10 {
        status.Warnings = append(status.Warnings, "WAL file is unusually large")
    }
    
    return status
}

func (dm *DatabaseManager) startMaintenanceRoutines() {
    // Periodic backup
    if dm.config.BackupInterval > 0 {
        ticker := time.NewTicker(dm.config.BackupInterval)
        go func() {
            for range ticker.C {
                backupPath := fmt.Sprintf("%s.backup-%s", dm.dbPath, time.Now().Format("20060102-150405"))
                if err := dm.Backup(backupPath); err != nil {
                    log.Printf("Backup failed: %v", err)
                }
            }
        }()
    }
    
    // Periodic cleanup
    if dm.config.CleanupInterval > 0 {
        ticker := time.NewTicker(dm.config.CleanupInterval)
        go func() {
            for range ticker.C {
                dm.runCleanupTasks()
            }
        }()
    }
    
    // Periodic vacuum
    if dm.config.VacuumInterval > 0 {
        ticker := time.NewTicker(dm.config.VacuumInterval)
        go func() {
            for range ticker.C {
                dm.runVacuum()
            }
        }()
    }
}

func (dm *DatabaseManager) runCleanupTasks() {
    // Clean up expired sessions
    dm.db.Exec("DELETE FROM sessions WHERE last_activity < datetime('now', '-7 days')")
    
    // Clean up old conversation turns (keep last 1000 per conversation)
    dm.db.Exec(`
        DELETE FROM conversation_turns 
        WHERE rowid NOT IN (
            SELECT rowid FROM conversation_turns 
            ORDER BY conversation_id, turn_number DESC 
            LIMIT 1000
        )
    `)
    
    // Clean up expired tool cache entries
    dm.db.Exec("DELETE FROM tool_cache WHERE datetime('now') > datetime(created_at, '+' || ttl_seconds || ' seconds')")
    
    // Archive old task execution history
    dm.db.Exec("DELETE FROM task_execution_history WHERE start_time < datetime('now', '-30 days')")
}

func (dm *DatabaseManager) runVacuum() {
    // Run incremental vacuum to reduce fragmentation
    dm.db.Exec("PRAGMA incremental_vacuum")
    
    // Analyze tables for query optimization
    dm.db.Exec("ANALYZE")
}

type DatabaseHealthStatus struct {
    Status              string    `json:"status"`
    DatabaseSize        int64     `json:"database_size"`
    WALSize             int64     `json:"wal_size"`
    FragmentationRatio  float64   `json:"fragmentation_ratio"`
    CheckTime           time.Time `json:"check_time"`
    Warnings            []string  `json:"warnings,omitempty"`
    Error               string    `json:"error,omitempty"`
}
```

#### Storage Technology Recommendations Summary

**Final Recommendations:**

1. **Primary Storage: SQLite**
   - **Use for**: Sessions, conversations, user profiles, agent state
   - **Benefits**: ACID compliance, SQL flexibility, mature ecosystem
   - **Configuration**: WAL mode, memory temp store, optimized pragmas

2. **Alternative Storage: BBolt**
   - **Use for**: Simple key-value caching, temporary data
   - **Benefits**: High performance, small footprint, embedded
   - **Use cases**: Tool result caching, short-term session data

3. **Hybrid Approach**
   - **In-memory caching** for frequently accessed data (LRU caches)
   - **SQLite persistence** for durability and complex queries
   - **Background sync** between cache and storage

4. **Configuration Management**
   - **Database path**: `~/.agent/data/agent.db`
   - **Backup strategy**: Automatic daily backups with rotation
   - **Maintenance**: Periodic cleanup, vacuum, and health checks
   - **Monitoring**: Size limits, fragmentation tracking, performance metrics

This comprehensive storage solution ensures the agent system can:
- **Run completely self-contained** with no external dependencies
- **Maintain excellent performance** through caching and optimization
- **Provide data durability** with proper backup and recovery
- **Scale appropriately** for single-user and small team usage
- **Support complex queries** for analytics and user preferences
- **Handle concurrent access** safely with proper locking and transactions
</rewritten_file>