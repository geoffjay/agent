# Agent

## Meta

Updating this plan will be necessary as the project evolves. Sections that mention that more work,
or more research is required are candidates for contributions. All sections can benefit from
questions being added where there are unknowns, or potential for improvements over what has been
proposed.

## OTA Updates

The command `agent update` should:

1. check the current tool version
2. check available versions that have been released
3. prompt the user to install the newest version
4. compare a checksum of the currently installed binary to the one kept in a repository for that version
5. if the checksum is a match it confirms the binary has not been manipulated and can be updated and proceeds
6. if the checksum is not a match an error is given and updates are prevented
7. the updated file is downloaded and used to update

## Configuration

The `internal/agent` package used internally by the `agent` applications provides definitions for AI
agents that can be used as a chat agent used interactively by a user, or an autonomous agent that is
executed through an `Agentfile` configuration using `agent run`. The configuration format is still a
work-in-progress, but the first version of the specification should resemble:

```yaml
---
agents:
  - name: dev-refactor-agent:v1
    model: claude-4-sonnet
    mode: autonomous
    tasks: ".agent/issues/refactoring.xit"
  - name: dev-documentation-agent:v1
    model: gemini-2.5
    mode: autonomous
    tasks: ".agent/issues/documentation.xit"
  - name: dev-coding-agent:v2
    model: claude-4-sonnet
    mode: chat
```

This configuration defines three agents, but `agent run` should only create processes for the ones
that are given autonomous as a mode. Agent definitions with the chat mode are meant to be used by the
`agent chat` command which should take `--name=dev-coding-agent:v2` as an argument to start with the
specific agent loaded, or it should provide a menu to allow the user to select one of the options.

A configuration specification needs to be created that can be used within the `Agentfile` files for
validation purposes. The `Agentfile` can be different types, including `json`, `yml/yaml`, and `toml`.
Since this is the case, specification should be defined that can either be used by all of these file
types, or each file type should have it's own specification defined.

## Agents

All agents should be created using the langchain framework along with langgraph, information for that
is given as:

- [langchaingo github code repository](https://github.com/tmc/langchaingo)
- [langchaingo online documentation](https://tmc.github.io/langchaingo/docs/)
- [langchaingo go package API documentation](https://pkg.go.dev/github.com/tmc/langchaingo)
- [langgraphgo github code repository](https://github.com/tmc/langgraphgo)
- [langgraphgo go package API documentation](https://pkg.go.dev/github.com/tmc/langgraphgo)

These libraries are Go implementations of Python libraries, the websites are these can be found at
[LangChain](https://python.langchain.com/docs/introduction/) and [LangGraph](https://langchain-ai.github.io/langgraph/). Python **must** never be used for this project as the purpose is for everything for the
agents to be built using Go.

The following rules should be followed when creating a new agent:

- an agent **should** always be versioned and kept in eg. `internal/agent/dev/coding/v1
- agents **must** be given a name as a constant `NAME` that they will be referred to as

### Runtime Linking

Agents will initially be defined by this project, but an eventual goal is that the project provides
an interface for linking other agents that have been defined at runtime. This would enable an
open-core design that can be extended by agent developers external to the project.

**important** this section requires research

### Generator

The `agent` CLI should be updated to support delegate commands such that when an application with the
name `agent-foo` exists in the users `PATH` executing `agent foo` will run that program. An
`agent-generate` application should be created as developer tooling so that executing `agent generate`
will ask the user for input necessary along with templates that have been added to create a new
agent in this project. For example, `agent generate --category "dev" --name "go-testing" --version "v1"`
would create a new agent definition in `internal/agent/dev/go_testing/v1/agent.go`.

### Runtime Generation from Definition

Ultimately, agents should be possible to be defined using something simpler than code. An agent
developer should be able to write an agent definition file that is read at runtime and used to create
an agent. It would define prompts, nodes, the decision graph, and anything else that is fundamental
to creating and running an AI agent.

**important** this section requires research

### Mode

The mode of an AI agent can be `autonomous` or `chat`, in autonomous mode the agent would be expected
to make an initial decision about what it should do as a task by reading from the tasks xit file that
it was provided in the `tasks` key of the configuration. Agents configured for chat mode should not
make decisions based on the taks file and should instead wait for the user to prompt them.

#### Autonomous

**important** this section requires research

#### Chat

**important** this section requires research

### Tasks and Task Integrations

#### Xit Files

**important** this section requires research

#### Github

**important** this section requires research

#### Gitlab

**important** this section requires research

#### Linear

**important** this section requires research

## Licensing

Ideally, a license model that supports open-source development while limiting the ability for other
for-profit entities taking the source and profiting from it without the upstream project and authors
benefiting from that would be used. Alternatively, a fully GPL license model may be opted for.

**important** this section requires research