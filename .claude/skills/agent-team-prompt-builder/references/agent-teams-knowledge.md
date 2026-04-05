# Agent Teams & Sub-Agents Knowledge Base

Reference doc for the agent-team-prompt-builder skill. Contains best practices, patterns, and gotchas distilled from official Anthropic docs, OpenAI's GPT-4.1 guide, and community experience (2026).

## Contents
- Agent Teams Overview
- Sub-Agents Overview
- Team Structure Patterns
- Prompt Engineering for Agent Teams
- MCP Tool Pre-Flight Patterns
- Common Pitfalls
- Token Cost Considerations

---

## Agent Teams Overview

Agent teams coordinate multiple independent Claude Code sessions working as a collaborative unit. One session acts as team lead, coordinating work and assigning tasks. Teammates run in separate sessions with their own full context windows and can message each other directly.

**Key characteristics:**
- Each teammate is a full, independent Claude Code session
- Teammates communicate via direct messaging (mailbox system)
- Shared task list for coordination
- Teammates do NOT inherit the lead's conversation history
- Token cost scales linearly: 3 teammates = ~3-4x tokens of single session

**Requirements:**
- Claude Code v2.1.32+
- Must enable: CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 in settings.json

---

## Sub-Agents Overview

Sub-agents are specialized workers within a single session. They run in their own context window, execute a task, and return results to the main agent. They cannot communicate with each other.

**Built-in types:**
- Explore (Haiku, read-only): Fast codebase search and analysis
- Plan (inherits model, read-only): Research during plan mode
- General-purpose (inherits model, all tools): Complex multi-step tasks

**When to use sub-agents vs teams:**
- Sub-agents: focused tasks returning results, cost-sensitive, no inter-agent discussion needed
- Teams: parallel collaboration, teammates need to share findings, complex multi-domain work

---

## Team Structure Patterns

### Pattern A — Research First, Then Implement
Best for: tasks requiring deep understanding before changes.
1. Main agent spawns Explore sub-agents to research codebase in parallel
2. Main agent synthesizes findings into implementation plan
3. Main agent creates team with implementation specialists

### Pattern B — Parallel Specialists from Start
Best for: clearly separable domains (frontend + backend + database).
1. Create team immediately with domain specialists
2. Each teammate owns a domain with clear file boundaries
3. Teammates use sub-agents for their own research

### Pattern C — Sequential Pipeline
Best for: tasks with strong dependencies.
1. Create team with architect + implementers
2. Architect plans and creates tasks in dependency order
3. Implementers pick up tasks as they become unblocked

### Pattern D — Investigate Then Divide
Best for: bug fixes, performance issues, unclear scope.
1. Create team with investigator + fixers
2. Investigator researches the problem, creates specific fix tasks
3. Fixers execute remediation in parallel

---

## Prompt Engineering for Agent Teams

### The #1 Rule: Full Context in Spawn Prompts
Teammates start with a BLANK conversation. The spawn prompt is everything they know. Include:
- Project tech stack and conventions
- Specific file boundaries (directories/files they own)
- Files they must NOT edit (owned by other teammates)
- Their specific task with clear steps
- Success criteria
- Communication protocol (when to message lead/peers)

### Three Agentic Essentials (from OpenAI's research)
Every agent prompt should include:
1. **Persistence**: "Keep going until all tasks are completely resolved. Do not yield back until done."
2. **Tool-calling**: "Use tools to discover information. Do NOT guess or make up answers."
3. **Planning**: "Before each major action, plan your approach explicitly."

### Anthropic-Specific Tips
- Use XML tags for structure in prompts
- Embed 3-5 examples when format matters
- Place long context at the top, instructions at the bottom
- Be explicit about desired behavior — don't rely on inference
- Claude 4.6 is more concise by default; ask for summaries if you want them
- Avoid over-prompting: "CRITICAL: You MUST..." → "Use this tool when..."

### Task Sizing
- 5-6 tasks per teammate (sweet spot)
- Too granular = coordination overhead
- Too broad = loses parallelism benefits
- 3-5 teammates for most workflows

---

## MCP Tool Pre-Flight Patterns

When a task requires MCP tools (Supabase, Playwright, Datadog, etc.), the coding agent must verify access BEFORE starting work.

### Pre-flight check template:

    Before starting any implementation work, verify access to all required tools:

    1. Supabase: Run a simple query (e.g., list_tables) to verify database access
    2. Playwright: Navigate to the app URL and take a screenshot to verify browser access
    3. [Other MCP tools]: Run minimal test operation

    If ANY tool fails:
    - STOP immediately
    - Report exactly which tools failed and what error occurred
    - List what permissions or configuration changes are needed
    - Wait for the user to resolve before proceeding

    If ALL tools work:
    - Report: "Pre-flight check passed. All N tools verified. Proceeding."
    - Continue immediately without waiting for user confirmation

---

## Common Pitfalls

1. **Not giving teammates context** — They don't inherit lead's history
2. **File conflicts** — Multiple teammates editing same files → overwrites
3. **Lead implementing instead of delegating** — Defeats parallelism
4. **Too many teammates** — Diminishing returns past 5, coordination overhead increases
5. **Sequential work in a team** — If tasks are sequential, a single session is cheaper
6. **Vague done criteria** — "Works correctly" is not verifiable
7. **Missing test instructions** — Agent may skip testing if not explicitly told
8. **Not specifying file boundaries** — The #1 cause of team conflicts

---

## Token Cost Considerations

Agent teams are token-heavy:
- 3-teammate team: ~3-4x tokens of single session
- 5-teammate team: ~5-7x tokens
- Each teammate has independent context window

Optimize by:
- Using cheaper models (Haiku/Sonnet) for research sub-agents
- Starting with read-only investigation before implementation
- Keeping teams small (3-5 is the sweet spot)
- Assigning non-overlapping file ownership to prevent rework
