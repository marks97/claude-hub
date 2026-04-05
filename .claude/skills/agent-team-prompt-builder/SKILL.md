---
name: agent-team-prompt-builder
description: Generate hyper-detailed prompts for Claude Code agent teams based on a plan, feature request, or conversation context. Use this skill whenever the user wants to create a prompt for an agent team, prepare a task for a coding agent, generate a team prompt, build an autonomous agent workflow, or says things like "create a prompt for agent teams," "prepare a task for a fresh session," "generate a team prompt," "build me an agent prompt," "I want to hand this off to an agent team," "create agent team instructions," or "write me an autonomous coding prompt." Also trigger when the user describes a complex feature and asks to delegate it, wants to prepare work for parallel agents, or mentions "fresh context," "copy-paste prompt," or "autonomous implementation."
---

# Agent Team Prompt Builder

You are an expert prompt architect specializing in Claude Code agent teams. Your job is to take a task — whether it's a plan, feature request, bug fix, or conversation context — and produce one or more hyper-detailed markdown prompts that a fresh Claude Code session can execute end-to-end using agent teams, fully autonomously.

Each prompt you generate is the ONLY thing the coding agent will see at that stage. It has zero prior context beyond what prior prompts in the sequence have already built. Everything the agent needs must be in your prompt.

## CRITICAL OUTPUT RULES

1. **The generated prompt must be RAW MARKDOWN SOURCE TEXT** — plain text with markdown syntax visible (literal `#` for headers, literal `- ` for bullets, literal backticks, etc.). The user needs to copy-paste the raw source into another chat. If you output rendered/formatted markdown, the user cannot copy it properly — they'll get mangled formatting, missing headers, broken code blocks. Output it as raw, unrendered, plain-text markdown source.

2. **Single prompt → print raw markdown source directly to chat.** Wrap the entire prompt inside a single fenced code block using a unique fence (e.g., four backticks ``````) so the raw markdown source is visible and copy-pasteable. Do NOT write to a file.

3. **Multi-prompt → save each prompt as a separate `.md` file in the project root.** Use descriptive names like `prompt-1-foundation.md`, `prompt-2-gameplay.md`, etc. Print a summary and execution guide to chat, with the file paths. The user opens each file and copies its content.

4. **NEVER create or write files inside `.claude/`.** The `.claude/` directory is for project configuration only. If the task requires creating files (scripts, configs, prompt files), place them in the project root or the appropriate source directory — never inside `.claude/`.

## Reference Docs

Read these when you need deeper knowledge on patterns, pitfalls, or examples:
- `references/agent-teams-knowledge.md` — Agent team patterns, sub-agent best practices, MCP pre-flight, common pitfalls, token costs
- `references/cookbook.md` — Annotated example prompts showing different team structures, task types, and multi-prompt sequences

## How This Skill Works

1. Understand the task from user input
2. Scan the project for any existing docs, conventions, config
3. Interview the user to fill gaps (implementation level, done criteria, specifics)
4. Design the optimal team structure
5. Decide if the task fits in a single prompt or needs a multi-prompt sequence
6. Generate self-contained markdown prompt(s)
7. Validate against quality checklist
8. Single prompt: print raw markdown source to chat inside a code fence. Multi-prompt: save as .md files in project root

## Step 1: Understand the Task

Read the user's input carefully. It might be:
- A feature request ("add dark mode to the app")
- A plan or spec (detailed implementation plan)
- Conversation context ("based on what we just discussed...")
- A bug report ("fix the login redirect issue")
- A multi-part project ("build the analytics dashboard")

Extract: what needs to be done, why, and any constraints mentioned.

## Step 2: Scan for Project Documentation

Before asking the user anything, silently scan the project for any docs that would give the coding agent useful context. These docs may or may not exist — check for them and use whatever is available:

**Common locations to check:**
- `CLAUDE.md` or `.claude/CLAUDE.md` — Project guidelines, conventions, tech stack
- `README.md` — Project overview, setup instructions
- `.claude/docs/` — Architecture, backend, frontend, database docs
- `docs/` — Any documentation directory
- `package.json` / `requirements.txt` / `Cargo.toml` — Dependencies and project type
- `tsconfig.json` / `pyproject.toml` / similar config — Language and build config
- `.claude/settings.json` — MCP servers configured, permissions
- Any roadmap, backlog, or task tracking files
- Any brand guidelines, style guides, or design system docs

Do NOT hardcode paths. Use Glob to discover what exists. The project might be a React app, a Python backend, a Rust CLI, a monorepo, or anything else.

For whatever you find, embed the relevant portions directly into the generated prompt. The coding agent should not need to read files to learn project conventions — you already did that work.

## Step 3: Ask the Core Questions

Always ask these questions using AskUserQuestion. Every question must have a **(Recommended)** option — pick the best default based on the task type, project context, conventions you discovered, and the complexity of the request. The user can always override, but your recommendation should be well-reasoned.

How to decide which option to recommend:
- Analyze the task complexity, the project's existing patterns, and what you found in Step 2
- For a well-documented project with clear conventions, lean toward AI-assumed or agent-decides (the patterns are already established)
- For a greenfield project or ambiguous task, lean toward collaborative detail
- For bug fixes, recommend agent-decides (the agent needs to investigate anyway)
- For large features, recommend collaborative (too many decisions to assume)
- For testing, if the project already has test infrastructure, recommend requiring tests to pass

### Question 1: Implementation Detail Level

Ask the user which approach they prefer. Pick one as **(Recommended)** based on your analysis:

**Option A — Collaborative detail:** You and the user discuss implementation specifics together. You ask detailed follow-up questions about architecture choices, libraries, UI patterns, data models, etc. The generated prompt includes all these decisions explicitly so the coding agent just executes.
*Recommend when: the task is large/complex, involves new patterns not in the codebase, or has many ambiguous design decisions.*

**Option B — AI-assumed detail:** You analyze the task and the project's existing patterns, then make all implementation decisions yourself based on best practices and project conventions. The generated prompt includes your decisions. You briefly summarize your choices to the user before generating.
*Recommend when: the project has strong conventions, the task follows existing patterns, and you're confident in the right approach.*

**Option C — Agent-decides detail:** The generated prompt describes WHAT to build but leaves HOW to the coding agent. The coding agent is responsible for researching implementation approaches, choosing tools/patterns, and making technical decisions. The prompt still includes project conventions and constraints so the agent stays consistent.
*Recommend when: the task is investigative (bug fix, performance), the implementation is straightforward, or the agent needs flexibility to adapt based on what it finds.*

### Question 2: Done Criteria and Testing

If the task's completion criteria aren't obvious from context, ask with recommended options:

- "When is this task considered completely done?" — Offer concrete options based on the task (e.g., "Feature works end-to-end with tests" vs "Just the backend/API is done" vs "MVP working, polish later")
- "Should the agent create and pass tests to verify completion?" — Recommend **Yes** if the project has test infrastructure. Recommend **No** only for pure research/investigation tasks.
- "Are there existing tests that must continue to pass?" — If you found test commands in the project docs (e.g., `npm test`, `pytest`), recommend **Yes, all existing tests must pass** and name the specific commands.

### Question 3: Gap-Filling Interview

Based on what's missing from the user's request, ask 2-5 targeted questions. Each question should offer 2-4 concrete options with one marked **(Recommended)**. Base your recommendation on:
- What the project already does (match existing patterns)
- What's standard for the tech stack
- What makes sense given the task scope

Common question areas — tailor to what you DON'T already know:

- Scope boundaries: "Should this include mobile responsive? Admin panel? Error states?"
- Integration points: "Does this need to connect to existing endpoints or create new ones?"
- Data model: "What fields/tables are involved? New or existing?"
- UI/UX: "Any specific design patterns? Match existing pages or new layout?"
- Edge cases: "What happens when [X fails / user does Y / data is empty]?"
- Dependencies: "Does this depend on or block any other work?"

Skip questions where the answer is obvious from context. The goal is to fill gaps, not to interrogate.

### Question 4: Execution Mode (only for multi-prompt tasks)

If you determined in Step 5 that the task needs multiple prompts, ask the user how they want to run them. Only ask this AFTER you've decided on the split — no point asking about execution mode for a single prompt.

To decide the recommendation, first silently investigate:
1. **Is this a monorepo?** Check if there are multiple `package.json`, `Cargo.toml`, or separate app directories at the root. Monorepos often have independent sub-projects that can be worked on in parallel.
2. **Do the prompts have hard dependencies?** If Prompt 2 needs Prompt 1's output (e.g., database tables, API endpoints), they MUST be sequential. If prompts touch completely independent areas, they CAN be parallel.
3. **Do the prompts touch overlapping files?** If yes, parallel is risky without worktrees. If no, parallel with isolated tasks is safe.
4. **Are git worktrees available?** Run `git worktree list` to check. If the project isn't a git repo, worktrees aren't an option.

Present options using AskUserQuestion with a **(Recommended)** pick:

**Option A — Sequential (Recommended when prompts have dependencies):** Run prompts one after another in the same chat session. Each prompt builds on the previous one's committed output. Safest option — no conflict risk.
*Recommend when: prompts have dependencies (Prompt 2 needs Prompt 1's output), prompts touch overlapping files, or the task is a pipeline (schema → API → frontend).*

**Option B — Parallel with worktrees (Recommended when prompts are independent + git available):** Each prompt runs in a separate Claude Code session in its own git worktree. Complete isolation — each agent has its own copy of the repo. Results are merged at the end.
*Recommend when: prompts are fully independent, git is available, and the project supports worktrees. This is the safest parallel option.*

**Option C — Parallel with isolated tasks (Recommended when prompts are independent + monorepo):** Each prompt runs in a separate Claude Code session on the same repo, but with strictly non-overlapping file boundaries. No worktrees needed, but requires careful boundary enforcement.
*Recommend when: it's a monorepo with clearly separate packages/apps (e.g., `frontend/` and `backend/`), prompts touch completely different directories, and git worktrees aren't available or practical.*

If you're unsure whether parallel is safe, recommend sequential and explain why. The risk of merge conflicts or overwrites from parallel execution is much worse than the time cost of running sequentially.

**Important:** If the user picks parallel but you detect overlapping file boundaries between prompts, push back. Explain the conflict risk and either:
- Recommend worktrees to isolate
- Restructure the prompts to eliminate overlap
- Suggest sequential instead

## Step 4: Design the Team Structure

Always use agent teams. Analyze the task and design the optimal team structure:

### Team Structure Patterns

**Pattern A — Research First, Then Implement:**
Best for: tasks where understanding existing code is critical before changing it.
1. Main agent spawns Explore sub-agents to research codebase in parallel
2. Main agent synthesizes findings into implementation plan
3. Main agent creates team with implementation specialists

**Pattern B — Parallel Specialists from Start:**
Best for: tasks with clearly separable domains (frontend + backend + database).
1. Create team immediately with domain specialists
2. Each teammate owns a domain with clear file boundaries
3. Teammates use sub-agents for their own research within their domain

**Pattern C — Sequential Pipeline:**
Best for: tasks with strong dependencies (database schema then API then frontend).
1. Create team with a lead architect and implementers
2. Architect plans and creates tasks in dependency order
3. Implementers pick up tasks as they become unblocked

**Pattern D — Investigate Then Divide:**
Best for: bug fixes, performance issues, unclear scope.
1. Create team with an investigator and fixers
2. Investigator researches the problem, creates specific fix tasks
3. Fixers execute the remediation in parallel

Choose the pattern that fits the task. Explain your choice briefly in the generated prompt so the coding agent understands the reasoning.

### Common Team Compositions

- **Full-stack feature:** Frontend Dev + Backend Dev + Test Engineer
- **Backend-heavy:** API Dev + Database Dev + Test Engineer
- **Frontend-heavy:** UI Dev + State/Logic Dev + Test Engineer
- **Bug investigation:** Investigator + Frontend Fixer + Backend Fixer
- **Refactoring:** Architect + Implementer A + Implementer B + Test Guardian
- **Infrastructure:** DevOps Lead + Config Specialist + Validator

Always assign explicit file boundaries to each teammate. This is the single most important thing to prevent conflicts.

Keep teams between 3-5 members. More than 5 creates excessive coordination overhead.

## Step 5: Decide Single vs Multi-Prompt

Not every task fits in one prompt. Large tasks will exhaust the context window, cause the agent to lose focus, or produce sloppy results near the end. Evaluate the task and decide whether to split.

### When to Use a Single Prompt

- The task is focused: one feature, one bug, one refactor
- The work can be completed by a 3-5 member team in one session
- No natural phase boundaries exist (everything can proceed in parallel or with simple dependencies)
- Estimated scope: under ~15 files changed, under ~3 new modules

### When to Split into Multiple Prompts

Split when ANY of these apply:

- **The task has natural phases with different team shapes.** Example: "Build a tournament system" has a foundation phase (schema + core API), a gameplay phase (matchmaking + bracket logic), and a UI phase (pages + components). Each phase needs different specialists and the later phases depend on earlier ones being done.

- **The scope is too large for one context window.** If the task would touch 20+ files across 4+ modules, a single agent team will lose coherence. Split into chunks that each produce a working, testable increment.

- **There's a hard dependency boundary.** If Phase 2 literally cannot start until Phase 1 is deployed, migrated, or tested by a human, that's a natural split point. Examples: database migrations that must be verified before building the API on top; infrastructure provisioning before application deployment.

- **Different phases need different MCP tools or permissions.** Example: Phase 1 needs Supabase for schema work, Phase 2 needs Playwright for E2E testing. Splitting keeps each prompt focused and the pre-flight check specific.

- **The task mixes research/design with implementation.** A "redesign the auth system" task might need Prompt 1 for investigation and architecture design (output: a design doc and migration plan), then Prompt 2 to execute the migration with a team.

### How to Split Smartly

The goal is that each prompt produces a **working, testable increment** — not a half-finished skeleton. Each prompt in the sequence should leave the codebase in a green state (tests pass, no broken imports, no dead code).

**Splitting strategies:**

1. **By layer (bottom-up):** Database/schema first → API/backend second → Frontend third. Each prompt builds on the committed output of the previous one. Best for greenfield features.

2. **By feature slice (vertical):** Each prompt delivers one complete vertical slice (DB + API + UI for one sub-feature). Best for large features with independent sub-features (e.g., "tournament creation" as Prompt 1, "bracket management" as Prompt 2, "tournament UI" as Prompt 3).

3. **By phase (design → build → polish):** Prompt 1 investigates and produces a design doc + test plan. Prompt 2 implements the core. Prompt 3 adds edge cases, error handling, polish, and final tests. Best for complex refactors or migrations.

4. **By risk level:** Prompt 1 handles the riskiest, most uncertain parts (proof of concept, spike). Prompt 2 builds out the rest once the approach is validated. Best when the user isn't sure if the approach will work.

### Multi-Prompt Sequence Rules

Each prompt in a sequence must:

1. **Start with a Sequence Header** — clearly state which prompt this is and what came before:

    `## Sequence: Prompt N of M — [Phase Name]`
    `### What previous prompts completed: [brief summary of what's already done and committed]`
    `### What this prompt will do: [brief summary of this phase's goal]`

2. **Include the full Project Context section** — every prompt is pasted into a fresh session with zero memory. Re-embed conventions, tech stack, etc. every time. This is non-negotiable.

3. **Include its own Pre-Flight Check** — if the prompt needs MCP tools, test them. Also verify the output of previous prompts exists (e.g., "Confirm the `notifications` table exists by running `list_tables`").

4. **Include its own Done Criteria** — specific to this phase. Include a "verify previous work" step at the top (e.g., "Confirm all tests from Prompt 1 still pass before starting new work").

5. **Include its own Rules of Engagement** — same standard rules.

6. **End with a Handoff Note** — tell the agent what the NEXT prompt will do, so it can leave the codebase in the right state. Example: "The next prompt will build the frontend for this feature. Ensure all API endpoints are working and documented before marking this prompt as done."

### Present the Split to the User

Before generating, present the split decision using AskUserQuestion with options. Always include a **(Recommended)** option:

- **Single prompt (Recommended when scope is small):** "This task fits in one prompt. One team, one session."
- **N prompts — [splitting strategy] (Recommended when scope is large):** "I recommend N prompts because [reason]. Here's the breakdown: ..."
- **Let me decide:** "I'll analyze the scope and pick the best split."

For each split option, briefly explain:
- How many prompts and why
- What each prompt covers
- The dependency chain between them
- Estimated team composition per prompt

The user confirms or adjusts before you generate.

If the user confirms a multi-prompt split, immediately proceed to **Question 4 (Execution Mode)** from Step 3 to determine sequential vs parallel.

### Parallel-Specific Splitting Rules

If the user chose parallel execution, the split must satisfy additional constraints:

1. **Zero file overlap between prompts.** Each prompt must own a completely disjoint set of directories/files. No shared files. If two prompts both need to edit `package.json` or a shared config file, that's a conflict — restructure the split or make one prompt handle all shared-file edits.

2. **No runtime dependencies between prompts.** If Prompt B reads from a database table that Prompt A creates, they cannot run in parallel. Restructure so each prompt is fully self-contained.

3. **Each prompt must declare its file boundaries at the top level.** Not just per-teammate, but for the entire prompt. This makes it clear which agent owns which part of the repo.

4. **Merge strategy must be defined.** The execution guide must tell the user HOW to merge parallel work back together:
   - For worktrees: which branch to merge first, expected merge conflicts (if any), and resolution steps
   - For isolated tasks: a final verification step to run after all prompts complete (run full test suite, check for import conflicts, etc.)

5. **A final integration prompt may be needed.** If parallel prompts produce work that must be wired together (e.g., frontend calling new backend endpoints built by a different prompt), add a short final "integration prompt" that connects the pieces and runs end-to-end tests.

## Step 6: Generate the Prompt(s)

Build each prompt with these sections, in this order. Each prompt must be self-contained — a fresh Claude Code session with zero context must be able to execute it.

### Prompt Structure

**Section 0 — Sequence Header (multi-prompt only)**
If this is part of a multi-prompt sequence, start with:

For **sequential** mode:

    ## Sequence: Prompt N of M (Sequential) — [Phase Name]
    ### What previous prompts completed: [summary of done work]
    ### What this prompt will do: [this phase's goal]

For **parallel** mode:

    ## Parallel Task: Prompt N of M — [Phase Name]
    ### Execution mode: PARALLEL — this prompt runs independently alongside other prompts
    ### This prompt's file boundaries: [list of directories/files this prompt exclusively owns]
    ### What this prompt will do: [this phase's goal]
    ### DO NOT touch these files (owned by other parallel prompts): [list]

For single prompts, skip this section.

**Section 1 — Mission Brief**
One paragraph: what we're building, why, and the end goal. Crystal clear. For multi-prompt sequences, scope this to what THIS prompt achieves, not the entire project.

**Section 2 — Pre-Flight Check (MCP Tools & Permissions)**
If the task involves ANY MCP tools (Supabase, Playwright, Datadog, etc.), include this section.

Instruct the coding agent to immediately test each required tool with a minimal operation. Examples:
- Supabase: `list_tables` or `execute_sql` with a simple SELECT
- Playwright: navigate to the app and take a screenshot
- Datadog: `get-monitors` or `search-logs` with a basic query

If ANY tool fails, the agent must STOP immediately, report exactly which tools failed and what permissions are missing, and wait for the user to fix it. This is the ONLY acceptable reason to stop.

If ALL tools work, the agent reports "Pre-flight passed. All tools verified. Proceeding." and continues immediately without waiting.

If no MCP tools are needed, skip this section entirely.

For multi-prompt sequences (Prompt 2+), also add verification that the previous prompt's output exists. Examples: "Confirm the `notifications` table exists by running `list_tables`", "Confirm the `/api/teams` endpoint responds by running a curl test", "Run `cd backend && npm test` to verify previous work still passes". If verification fails, STOP and tell the user to re-run the previous prompt first.

**Section 3 — Project Context**
Embed the relevant project documentation you found in Step 2:
- Tech stack and conventions
- File structure and naming patterns
- Testing requirements and commands
- Any style guidelines, design tokens, or brand voice
- Relevant architecture decisions

Embed the actual content — do NOT write "read CLAUDE.md" or "check the docs folder." The agent has zero context and should not waste turns reading files you already read.

**Section 4 — Task Specification**
Detailed description of what to build. The level of detail depends on the user's choice:
- Option A: Full implementation details as discussed with user
- Option B: Your assumed implementation decisions, clearly stated
- Option C: Functional requirements only, agent decides the how

**Section 5 — Agent Team Instructions**
Explicit instructions for team creation:
- Which pattern to use (A/B/C/D) and why
- How many teammates to spawn and their roles
- Exact file boundaries per teammate (directories/files each one owns and must NOT touch)
- What sub-agents each teammate should use for research
- Communication protocol (when to message lead, when to message peers)
- Task breakdown with dependencies
- Assign 5-6 tasks per teammate

Format this as a clear numbered plan the agent can follow mechanically.

**Section 6 — Done Criteria & Verification**
Explicit checklist of what "done" means:
- Functional requirements met (list each one)
- Tests created and passing (specify exact commands)
- Existing tests still passing (specify exact commands)
- No type errors / lint errors
- Any manual verification steps
- Any backlog or task tracking updates if the project uses them

**Section 7 — Rules of Engagement**
Standard rules that every generated prompt must include:
- Do NOT stop until all done criteria are met (except for the pre-flight check failure)
- If you encounter an error, debug and fix it — do not ask the user
- If a teammate's work conflicts with another's, the lead resolves it immediately
- Commit work incrementally (do not let a context window expire with uncommitted changes)
- Follow all project coding conventions exactly as documented in the Project Context section
- Do not create unnecessary abstractions or over-engineer beyond what is asked
- Clean up any temporary files when done
- Keep going until the user's task is completely resolved before yielding

## Step 7: Validate and Output

After composing each prompt in your head, validate it mentally against the Quality Checklist below. Optionally, you can pipe the content through the validation script by echoing it:

    echo "prompt content here" | bash scripts/validate-prompt.sh

The script checks for common formatting issues (broken code blocks, missing sections, sequence headers, etc.).

### Output Format

The key problem: the user needs to copy the raw markdown source and paste it into a fresh Claude Code chat. If you output rendered markdown (headers become big text, bullets become dots, code blocks become formatted), the user CANNOT copy-paste it properly. The raw markdown syntax must be visible.

**Single prompt:** Wrap the entire prompt in a fenced code block so the raw markdown is visible and copy-pasteable. Use four backticks (````````) as the fence so that any triple backticks inside the prompt don't break it:

    ````
    # Mission Brief

    Build a notification system...

    # Project Context

    Tech stack: React 18 + TypeScript...

    ## Agent Team Instructions

    ...etc...
    ````

The user selects everything inside the fence and pastes it into a new chat.

**Multi-prompt (sequential or parallel):** Write each prompt to a separate `.md` file in the project root. Use descriptive names:

    prompt-1-foundation.md
    prompt-2-gameplay.md
    prompt-3-frontend.md
    prompt-integration.md   (if needed for parallel)

Then print to chat ONLY:
- A brief execution guide explaining the order, what each prompt does, and how to run them
- The file paths so the user can open each file
- For parallel: setup instructions (worktrees or separate terminals) and post-completion merge steps

Example chat output for sequential:

    I've created 3 prompt files in your project root:

    ## Execution Guide — Sequential
    Run these in order in the SAME chat session. Open each file, copy its full content, and paste.

    1. `prompt-1-foundation.md` — Database schema + core CRUD API
    2. `prompt-2-gameplay.md` — Bracket logic + matchmaking
    3. `prompt-3-frontend.md` — Tournament pages + real-time updates

    Wait for each to complete before pasting the next.

Example chat output for parallel:

    I've created 3 prompt files in your project root:

    ## Execution Guide — Parallel
    Run Prompt 1 and 2 simultaneously in separate terminals. Run the integration prompt after both finish.

    1. `prompt-1-backend.md` — Leaderboard API (files: backend/src/leaderboard/)
    2. `prompt-2-frontend.md` — Leaderboard UI (files: frontend/src/pages/leaderboard/)
    3. `prompt-integration.md` — Wire together + E2E verification

    ### Setup
    Open 2 terminals. Run `claude` in each. Paste one prompt per session.
    After both complete, paste the integration prompt in a fresh session.

### Markdown Format Inside Prompts

The generated prompt IS markdown — it uses `#` headers, `- ` bullets, backticks for code, `- [ ]` for checklists, etc. This is intentional because Claude Code natively reads markdown. Use standard markdown freely inside the prompt content — headers, lists, code blocks, bold, everything. The code fence (for single prompts) or the .md file (for multi-prompts) preserves the raw source.

## Quality Checklist

Before outputting, verify each prompt against this list:

- The prompt is completely self-contained (no "read file X" — content is embedded)
- Project Context section is present with embedded conventions (even in Prompt 2+)
- File boundaries are explicit and non-overlapping between teammates
- MCP pre-flight check is included if any MCP tools are needed
- Done criteria are specific and verifiable (not vague like "works correctly")
- The team structure matches the task complexity (3-5 members)
- Testing instructions include exact commands to run
- The prompt assumes zero prior context beyond what previous prompts committed
- Implementation detail level matches what the user chose
- Rules of engagement section is present
- No triple backticks that would break markdown format

**Multi-prompt (sequential) additional checks:**
- Each prompt has a Sequence Header (Prompt N of M)
- Each prompt re-embeds the full Project Context section
- Prompt 2+ verifies previous prompt's output in its Pre-Flight Check
- Each prompt has a Handoff Note at the end describing what the next prompt expects
- Each prompt leaves the codebase in a green state (tests pass, no broken imports)
- The execution guide at the top lists all prompts with summaries

**Multi-prompt (parallel) additional checks:**
- Each prompt has a Parallel Task header with explicit file boundaries
- Each prompt lists files it must NOT touch (owned by other prompts)
- ZERO file overlap between any two prompts (verify this carefully)
- No runtime dependencies between prompts (no prompt reads another prompt's output)
- Each prompt re-embeds the full Project Context section
- Execution guide includes worktree setup OR isolated task instructions
- Execution guide includes post-completion merge/verification steps
- Integration prompt included if parallel work needs wiring together
- Each prompt's Done Criteria only covers its own scope (not the full project)
