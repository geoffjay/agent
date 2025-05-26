# Task Integrations Research

## Overview

The agent system needs to integrate with various task management systems to enable autonomous agents to read, process, and update tasks from different sources. This research covers integration approaches for Xit files, GitHub Issues, GitLab Issues, and Linear Issues.

## Research Questions

1. **Task Abstraction**: How can we create a unified task model across different systems?
2. **Synchronization**: How should we handle bidirectional sync between systems?
3. **Authentication**: What authentication methods are required for each platform?
4. **Rate Limiting**: How do we handle API rate limits effectively?
5. **Conflict Resolution**: How do we handle conflicts when tasks are modified in multiple places?
6. **Offline Support**: How can agents work when external systems are unavailable?

## Task Data Model

### Unified Task Structure
```go
type Task struct {
    ID           string            `json:"id"`
    Source       TaskSource        `json:"source"`
    ExternalID   string            `json:"external_id"`
    Title        string            `json:"title"`
    Description  string            `json:"description"`
    Status       TaskStatus        `json:"status"`
    Priority     TaskPriority      `json:"priority"`
    Labels       []string          `json:"labels"`
    Assignees    []User            `json:"assignees"`
    CreatedAt    time.Time         `json:"created_at"`
    UpdatedAt    time.Time         `json:"updated_at"`
    DueDate      *time.Time        `json:"due_date,omitempty"`
    Metadata     map[string]any    `json:"metadata"`
    Comments     []Comment         `json:"comments"`
    Attachments  []Attachment      `json:"attachments"`
    Dependencies []TaskDependency  `json:"dependencies"`
}

type TaskSource string
const (
    TaskSourceXit    TaskSource = "xit"
    TaskSourceGitHub TaskSource = "github"
    TaskSourceGitLab TaskSource = "gitlab"
    TaskSourceLinear TaskSource = "linear"
)

type TaskStatus string
const (
    TaskStatusOpen       TaskStatus = "open"
    TaskStatusInProgress TaskStatus = "in_progress"
    TaskStatusCompleted  TaskStatus = "completed"
    TaskStatusCancelled  TaskStatus = "cancelled"
)
```

## Xit Files Integration

### Overview
Xit is a plain-text task management format that uses simple markup in text files.

### Format Specification
```
# Xit File Format
[ ] Open task
[x] Completed task
[~] Ongoing task
[?] Question/uncertain task
[@] Important task

# Tags and priorities
[ ] Task with @tag
[ ] Task with due:2024-01-15
[ ] High priority task !!!
[ ] Medium priority task !!
[ ] Low priority task !
```

### Implementation Approach

#### 1. File Parsing
```go
type XitParser struct {
    filepath string
}

type XitTask struct {
    Status      rune      // ' ', 'x', '~', '?', '@'
    Text        string    
    Tags        []string  
    Priority    int       // 0-3 based on ! count
    DueDate     *time.Time
    LineNumber  int
}

func (p *XitParser) Parse() ([]XitTask, error) {
    // Implementation for parsing xit files
}
```

#### 2. File Watching
```go
import "github.com/fsnotify/fsnotify"

type XitWatcher struct {
    watcher  *fsnotify.Watcher
    filepath string
    onChange func([]Task)
}

func (w *XitWatcher) Watch() error {
    // Watch for file changes and trigger parsing
}
```

#### 3. Bidirectional Sync
- **Read**: Parse xit files to extract tasks
- **Write**: Update xit files when tasks change in agent system
- **Conflict Resolution**: Use file timestamps and git-style merge conflict markers

### Advantages
- Simple format, easy to read and edit
- Version control friendly
- No external dependencies
- Offline-first approach

### Challenges
- Limited metadata support
- No collaborative editing
- Manual conflict resolution needed
- No attachment support

## GitHub Issues Integration

### API Overview
GitHub provides comprehensive REST and GraphQL APIs for issue management.

### Authentication Options
1. **Personal Access Tokens (PAT)**
2. **GitHub Apps** (recommended for production)
3. **OAuth Apps** (for user authorization)

### Implementation Approach

#### 1. API Client
```go
type GitHubClient struct {
    client *github.Client
    owner  string
    repo   string
}

func NewGitHubClient(token, owner, repo string) *GitHubClient {
    ts := oauth2.StaticTokenSource(&oauth2.Token{AccessToken: token})
    tc := oauth2.NewClient(context.Background(), ts)
    return &GitHubClient{
        client: github.NewClient(tc),
        owner:  owner,
        repo:   repo,
    }
}
```

#### 2. Task Synchronization
```go
func (gc *GitHubClient) FetchTasks(since *time.Time) ([]Task, error) {
    opts := &github.IssueListByRepoOptions{
        State: "all",
        Since: since,
    }
    
    issues, _, err := gc.client.Issues.ListByRepo(
        context.Background(), gc.owner, gc.repo, opts)
    if err != nil {
        return nil, err
    }
    
    var tasks []Task
    for _, issue := range issues {
        task := gc.convertIssueToTask(issue)
        tasks = append(tasks, task)
    }
    return tasks, nil
}
```

#### 3. Webhook Integration
```go
type GitHubWebhookHandler struct {
    secret []byte
    onTaskUpdate func(Task)
}

func (h *GitHubWebhookHandler) HandleWebhook(w http.ResponseWriter, r *http.Request) {
    payload, err := github.ValidatePayload(r, h.secret)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    event, err := github.ParseWebHook(github.WebHookType(r), payload)
    if err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    
    switch e := event.(type) {
    case *github.IssuesEvent:
        task := h.convertIssueEventToTask(e)
        h.onTaskUpdate(task)
    }
}
```

### Rate Limiting Strategy
- GitHub allows 5,000 requests/hour for authenticated requests
- Implement exponential backoff for rate limit responses
- Use GraphQL for efficient bulk operations
- Cache frequently accessed data

### Advanced Features
- **Labels and Milestones**: Map to task categories and projects
- **Assignees**: Support for task assignment
- **Comments**: Full comment thread support
- **Pull Request Linking**: Connect tasks to code changes

## GitLab Issues Integration

### API Overview
GitLab provides REST API v4 for issue management with similar functionality to GitHub.

### Implementation Approach

#### 1. API Client
```go
type GitLabClient struct {
    client    *gitlab.Client
    projectID int
}

func NewGitLabClient(token string, projectID int) *GitLabClient {
    client, _ := gitlab.NewClient(token)
    return &GitLabClient{
        client:    client,
        projectID: projectID,
    }
}
```

#### 2. Issue Fetching
```go
func (gc *GitLabClient) FetchTasks() ([]Task, error) {
    opts := &gitlab.ListProjectIssuesOptions{
        State: gitlab.String("all"),
    }
    
    issues, _, err := gc.client.Issues.ListProjectIssues(gc.projectID, opts)
    if err != nil {
        return nil, err
    }
    
    var tasks []Task
    for _, issue := range issues {
        task := gc.convertIssueToTask(issue)
        tasks = append(tasks, task)
    }
    return tasks, nil
}
```

### GitLab-Specific Features
- **Issue Boards**: Kanban-style task management
- **Epics**: Hierarchical task organization (Premium feature)
- **Time Tracking**: Built-in time estimation and tracking
- **Merge Request Integration**: Link issues to merge requests

## Linear Issues Integration

### API Overview
Linear provides GraphQL API for accessing issues, projects, and teams.

### Implementation Approach

#### 1. GraphQL Client
```go
type LinearClient struct {
    client *graphql.Client
    teamID string
}

func NewLinearClient(apiKey, teamID string) *LinearClient {
    client := graphql.NewClient("https://api.linear.app/graphql")
    client.HTTPClient = &transport{
        apiKey: apiKey,
    }
    return &LinearClient{
        client: client,
        teamID: teamID,
    }
}
```

#### 2. Issue Queries
```graphql
query GetIssues($teamId: String!, $first: Int!) {
  team(id: $teamId) {
    issues(first: $first) {
      nodes {
        id
        title
        description
        state {
          name
          type
        }
        priority
        assignee {
          name
          email
        }
        labels {
          nodes {
            name
            color
          }
        }
        createdAt
        updatedAt
      }
    }
  }
}
```

#### 3. Real-time Updates
```go
func (lc *LinearClient) SubscribeToUpdates() error {
    subscription := `
        subscription IssueUpdates($teamId: String!) {
            issueUpdate(teamId: $teamId) {
                action
                issue {
                    id
                    title
                    state { name }
                }
            }
        }
    `
    // WebSocket subscription implementation
}
```

### Linear-Specific Features
- **Cycles**: Sprint/iteration management
- **Projects**: Cross-team project tracking
- **Priority Levels**: Numerical priority system (0-4)
- **State Workflows**: Customizable issue state transitions

## Synchronization Strategy

### 1. Polling vs Push
```go
type SyncStrategy interface {
    Start(ctx context.Context) error
    Stop() error
}

// Polling-based sync
type PollingSync struct {
    interval time.Duration
    fetcher  TaskFetcher
}

// Webhook-based sync
type WebhookSync struct {
    endpoint string
    handler  WebhookHandler
}
```

### 2. Conflict Resolution
```go
type ConflictResolver interface {
    Resolve(local, remote Task) (Task, error)
}

type TimestampResolver struct{}

func (r *TimestampResolver) Resolve(local, remote Task) (Task, error) {
    if remote.UpdatedAt.After(local.UpdatedAt) {
        return remote, nil
    }
    return local, nil
}
```

### 3. Offline Support
```go
type TaskCache interface {
    Store(tasks []Task) error
    Load() ([]Task, error)
    GetUpdatedSince(since time.Time) ([]Task, error)
}

type SQLiteTaskCache struct {
    db *sql.DB
}
```

## Configuration Management

### Unified Configuration
```yaml
# Task integration configuration
task_sources:
  - type: xit
    path: ".tasks/todo.xit"
    watch: true
    
  - type: github
    owner: "username"
    repo: "project"
    token_env: "GITHUB_TOKEN"
    webhook_secret_env: "GITHUB_WEBHOOK_SECRET"
    
  - type: gitlab
    project_id: 12345
    token_env: "GITLAB_TOKEN"
    
  - type: linear
    team_id: "team-uuid"
    api_key_env: "LINEAR_API_KEY"

sync_strategy:
  method: "hybrid"  # polling, webhook, hybrid
  polling_interval: "5m"
  batch_size: 100
  
conflict_resolution:
  strategy: "timestamp"  # timestamp, manual, custom
  
cache:
  enabled: true
  backend: "sqlite"
  path: ".agent/task_cache.db"
```

## Security Considerations

### 1. Token Management
- Store API tokens in secure credential managers
- Support token rotation and refresh
- Implement least-privilege access principles

### 2. Webhook Security
- Validate webhook signatures
- Use HTTPS endpoints only
- Implement rate limiting on webhook endpoints

### 3. Data Privacy
- Encrypt sensitive task data at rest
- Implement data retention policies
- Support task data anonymization

## Performance Optimizations

### 1. Incremental Sync
- Track last sync timestamps
- Use API pagination efficiently
- Implement delta sync for large datasets

### 2. Caching Strategy
- Cache frequently accessed tasks
- Implement cache invalidation strategies
- Use ETags for conditional requests

### 3. Batch Operations
- Group multiple API calls where possible
- Use bulk update APIs when available
- Implement operation queuing for offline scenarios

## Implementation Roadmap

### Phase 1: Core Integration
1. Implement unified task data model
2. Create Xit file parser and watcher
3. Implement GitHub Issues basic sync
4. Create configuration management system

### Phase 2: Enhanced Features
1. Add GitLab and Linear integrations
2. Implement webhook support
3. Create conflict resolution system
4. Add offline caching capabilities

### Phase 3: Advanced Features
1. Implement real-time synchronization
2. Add advanced conflict resolution
3. Create task analytics and reporting
4. Implement custom integration plugins

## Testing Strategy

### 1. Unit Tests
- Test parsers with various input formats
- Mock API clients for integration testing
- Test conflict resolution scenarios

### 2. Integration Tests
- Test against real API environments
- Validate webhook delivery and processing
- Test offline/online transition scenarios

### 3. Performance Tests
- Load testing with large task datasets
- Rate limiting behavior validation
- Memory usage optimization verification

## Error Handling and Monitoring

### 1. Error Classification
```go
type TaskIntegrationError struct {
    Source    TaskSource
    Operation string
    Err       error
    Retryable bool
}
```

### 2. Monitoring Metrics
- API request success/failure rates
- Sync latency and frequency
- Cache hit/miss ratios
- Task processing throughput

### 3. Alerting
- API rate limit approaching
- Authentication failures
- Sync failures exceeding threshold
- Webhook delivery failures 
