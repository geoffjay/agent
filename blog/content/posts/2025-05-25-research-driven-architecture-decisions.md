---
title: "Research-Driven Architecture: How We Approached Foundational Design Decisions ��"
date: 2025-05-25T10:00:00-08:00
slug: "research-driven-architecture-decisions"
categories:
  - architecture
  - research
  - planning
tags:
  - design-decisions
  - research-methodology
  - agent-architecture
summary: "A deep dive into our research methodology for making foundational architectural decisions in the agent project, exploring how we balanced trade-offs and revised recommendations through systematic analysis."
provenance:
  repo: "https://github.com/geoffjay/agent"
  commit: "803b0a4ed1a95bbca1a8c9a38b2d01bae91ad773"
  prompt: "803b0a4ed1a95bbca1a8c9a38b2d01bae91ad773"
  modifications: []
---

When building a new software platform, especially one as ambitious as an AI agent system, the architectural decisions you make early on will echo throughout the project's lifetime. Rather than diving straight into implementation, we took a step back and conducted comprehensive research across four critical areas: runtime generation, runtime linking, agent operational modes, and licensing strategy.

This post explores our research methodology and the key decisions that emerged from this process—including some surprising changes to our initial assumptions.

## The Research Framework 🔬

Our approach was structured around a consistent methodology for each domain:

1. **Problem Definition**: Clearly articulating the questions we needed to answer
2. **Landscape Analysis**: Surveying existing solutions and approaches
3. **Trade-off Evaluation**: Systematically weighing pros and cons
4. **Implementation Planning**: Converting research into concrete roadmaps
5. **Decision Documentation**: Recording rationale for future reference

Each research area produced both a comprehensive research document and a detailed implementation plan, ensuring that insights translated directly into actionable development work.

## Runtime Generation: YAML Over Code

**Initial Assumption**: "We'll need a custom DSL for agent definitions"

**Research Reality**: YAML with JSON Schema validation emerged as the clear winner

The runtime generation research tackled how to enable agent creation without requiring Go programming knowledge. We evaluated three primary approaches:

### The Decision Matrix

| Approach | Developer UX | Validation | Tooling | Complexity |
|----------|-------------|------------|---------|------------|
| **YAML + Schema** | ✅ Familiar | ✅ Robust | ✅ Excellent | ✅ Low |
| **Custom DSL** | ⚠️ Learning curve | ✅ Built-in | ❌ Custom | ❌ High |
| **JSON Only** | ⚠️ Verbose | ✅ Robust | ✅ Good | ✅ Low |

The research revealed that YAML struck the perfect balance. While a custom DSL might seem more elegant, the development overhead and tooling requirements made it impractical for an early-stage project. Plus, developers already know YAML (even if they sometimes grumble about indentation).

**Key Insight**: Sometimes the "boring" choice is the right choice. YAML's ubiquity in the DevOps world made it a natural fit for agent definitions.

## Runtime Linking: Go Plugins vs gRPC Services

**Initial Assumption**: "We should use Go's plugin system for extensions"

**Revised Approach**: Go plugins for Unix, with gRPC services as future enhancement

This was where our research methodology really paid off. Our initial enthusiasm for Go's native plugin system hit some hard realities:

### The Platform Reality Check

- **Go Plugins**: Work great on Unix systems (Linux, macOS)
- **Windows Support**: Nonexistent for Go plugins
- **Cross-Platform**: gRPC services work everywhere but add operational complexity

**The Compromise**: Start with Go plugins for the primary development platforms, architect the system to easily add gRPC service support later for Windows compatibility.

**Lesson Learned**: Don't let perfect be the enemy of good. Shipping something that works well on 80% of target platforms beats never shipping at all.

## Agent Modes: The Resource Management Revelation

**Initial Assumption**: "Chat and autonomous modes are just different interaction patterns"

**Research Discovery**: Resource management is absolutely critical and differs dramatically between modes

The agent modes research uncovered what initially seemed like a minor implementation detail but turned out to be a fundamental architectural requirement: resource management.

### Why This Matters More Than Expected

Autonomous agents running in the background can consume unlimited resources without user awareness:
- **Memory**: Large context windows and conversation history
- **Network**: Expensive API calls to LLM providers  
- **CPU**: Complex reasoning and code analysis
- **Cost**: $3-30 per million tokens adds up quickly

Chat agents, being interactive, naturally have built-in constraints (users notice when things are slow or expensive). Autonomous agents needed entirely different resource management strategies.

**The Implementation Impact**: This research finding completely changed our architecture, requiring:
- Resource monitoring and limits per agent type
- Different execution strategies for each mode
- Cost tracking and budget enforcement
- Graceful degradation under resource pressure

## Licensing: From MIT to Apache 2.0 (Almost)

**Initial Inclination**: "MIT License for maximum adoption"

**Research Conclusion**: Apache 2.0 for patent protection and enterprise adoption

This research dove deep into the intersection of open source philosophy, business strategy, and legal pragmatism. The landscape analysis was eye-opening:

### The Enterprise Adoption Reality

Modern enterprises increasingly prefer Apache 2.0 over MIT for one key reason: **patent protection**. In an AI-heavy world where patent disputes are common, Apache 2.0's explicit patent grant provides legal clarity that MIT simply doesn't offer.

**The Surprise Finding**: While we expected GPL-style copyleft licenses to be too restrictive, Mozilla Public License 2.0 emerged as an interesting middle ground. Its file-level copyleft provides some protection against proprietary forks while remaining enterprise-friendly.

**Final Decision**: Apache 2.0, but with MPL 2.0 as a documented alternative if competitive dynamics change.

## Task Integrations: The Integration Explosion

**Research Question**: "How many task sources should we support?"

**Discovery**: The integration matrix explodes quickly, but patterns emerge

The task integration research revealed that while every organization has their preferred tools (GitHub Issues, Linear, Jira, Xit files, etc.), the underlying patterns are remarkably consistent:

- **Create/Read/Update** operations
- **Status workflows** (open → in progress → done)
- **Priority/labeling systems**
- **Comment/collaboration features**

**Key Architectural Decision**: Build a unified task abstraction layer that normalizes different sources into a common interface. This lets us support the "big three" (GitHub, Linear, local files) initially while making future integrations much simpler.

## The Meta-Learning 🎯

Beyond the specific technical decisions, this research process taught us several valuable lessons about architectural decision-making:

### 1. Research Prevents Regret

Spending time upfront exploring alternatives saved us from costly architectural pivots later. The resource management requirements for autonomous agents, for example, would have been painful to retrofit.

### 2. Document the "Why" Not Just the "What"

Each decision document includes not just the final choice, but the rationale and the alternatives considered. Future developers (including future us) will understand why certain paths were taken.

### 3. Challenge Your Assumptions Early

Several of our initial assumptions proved wrong under scrutiny. The research framework forced us to question everything before committing to code.

### 4. Implementation Plans Bridge Research and Reality

Research without implementation planning often leads to "analysis paralysis." By requiring concrete implementation roadmaps, we ensured that research translated into actionable development work.

## Looking Forward

This research foundation gives us confidence in our architectural decisions while maintaining flexibility for future evolution. We've built a system that can grow and adapt while staying true to core principles.

The next phase involves turning these research insights into working code—but that's a story for future blog posts. For now, we're excited to have a solid foundation built on thorough analysis rather than architectural guesswork.

*Sometimes the best code is the code you don't write until you're sure it's the right code to write.*

---

*This article was originally created in commit [`803b0a4ed1a95bbca1a8c9a38b2d01bae91ad773`](https://github.com/geoffjay/agent/commit/803b0a4ed1a95bbca1a8c9a38b2d01bae91ad773).* 
