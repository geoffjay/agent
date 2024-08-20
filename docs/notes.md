# Notes

## Idea

Create an agent using Langchain/Langgraph that monitors text files containing
issues and runs as a process creating code contributions. It should understand
the issues and create code contributions that solve the issues.

## Technology

- Ollama
- Langchain
- Langgraph
- ChromaDB

## Steps

The agent:

- runs as a process
- reads text files in `docs/issues`
- determines the highest priority issue
- creates a `git worktree` in `worktrees/issue-<issue-id>`
- creates a code contribution in the worktree
- commits the code contribution
- pushes the code contribution to the repository
- creates a pull request
- monitors the pull request for feedback
- updates the code contribution based on feedback
- merges the pull request once it's approved
- deletes the worktree

## Using Worktrees

An example command that creates a branch in a worktree:

```bash
git worktree add ../worktrees/issue-1 origin/main -b issue-1
```
