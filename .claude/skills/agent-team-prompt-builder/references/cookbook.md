# Agent Team Prompt Cookbook

Annotated examples showing different prompt structures for different task types. Read this for inspiration when building prompts — adapt the patterns, don't copy them verbatim.

## Contents
- Example 1: Full-Stack Feature (Parallel Specialists) — Single Prompt
- Example 2: Bug Investigation (Investigate Then Divide) — Single Prompt
- Example 3: Database Migration + API (Sequential Pipeline) — Single Prompt
- Example 4: Research-Heavy Task (Research First, Then Implement) — Single Prompt
- Example 5: Large Feature (Multi-Prompt Sequential) — 3 Prompts
- Example 6: Migration + Rebuild (Multi-Prompt Sequential, Design Then Build) — 2 Prompts
- Example 7: Monorepo Feature (Multi-Prompt Parallel with Isolated Tasks) — 2 Prompts + Integration
- Tips on Code Blocks in Prompts

---

## Example 1: Full-Stack Feature (Parallel Specialists)

**Scenario:** User wants to add a notifications system to their app. React frontend, Express backend, PostgreSQL database. Supabase MCP available.

**Why this pattern:** Frontend and backend work are clearly separable. Both can proceed in parallel once the data model is agreed on.

<example-prompt>
# Mission Brief

Build a real-time notification system. Users receive notifications for friend requests, game invitations, and achievement unlocks. Notifications appear as a bell icon with unread count in the header, with a dropdown panel showing recent notifications. Clicking a notification navigates to the relevant page.

# Pre-Flight Check

Before starting any implementation, verify these tools work:

1. Supabase: Run `list_tables` to confirm database access
2. Supabase: Run `execute_sql` with `SELECT 1` to confirm query access

If either fails, STOP and report what's missing. If both pass, say "Pre-flight passed" and proceed immediately.

# Project Context

Tech stack: React 18 + TypeScript, Express.js, Supabase (PostgreSQL), Socket.IO
File naming: kebab-case for files, PascalCase for components
Components: functional with hooks, no default exports
Styles: CSS modules, design tokens in `src/styles/tokens.css`
Tests: Jest + React Testing Library (frontend), Jest (backend)
Test commands: `cd frontend && npm test`, `cd backend && npm test`

(... rest of conventions embedded here ...)

# Task Specification

## Database
- Create `notifications` table: id (uuid), user_id (uuid FK), type (enum: friend_request, game_invite, achievement), title (text), body (text), link (text), read (boolean default false), created_at (timestamptz)
- Add RLS policy: users can only read/update their own notifications
- Create index on (user_id, read, created_at)

## Backend
- NotificationService: create, markAsRead, markAllAsRead, getUnread, getRecent(limit=20)
- REST endpoints: GET /notifications, PATCH /notifications/:id/read, PATCH /notifications/read-all
- Socket.IO event: emit `notification:new` to user's room when created

## Frontend
- NotificationBell component in header: bell icon + unread count badge
- NotificationPanel dropdown: list of recent notifications, "mark all read" button
- Each notification: icon by type, title, relative timestamp, click navigates to link
- Real-time: listen for `notification:new` socket event, update count

# Agent Team Instructions

Use Pattern B (Parallel Specialists). Create a team with 3 members:

1. **backend-dev** — Owns: `backend/src/notifications/`, `supabase/migrations/`
   - First: create the Supabase migration for the notifications table
   - Then: implement NotificationService, controller, and routes
   - Then: add Socket.IO emission on notification creation
   - Use Explore sub-agent to understand existing Socket.IO patterns in the project
   - Message frontend-dev when the API contract is finalized

2. **frontend-dev** — Owns: `frontend/src/components/notifications/`, `frontend/src/hooks/useNotifications.ts`
   - First: create NotificationBell and NotificationPanel components
   - Then: create useNotifications hook (fetch + socket listener)
   - Then: integrate bell into existing Header component (edit only the import and JSX for the bell)
   - Use Explore sub-agent to check existing header structure before modifying
   - DO NOT edit any files in `backend/`

3. **test-engineer** — Owns: `**/*.test.*` files for notifications only
   - Wait for backend-dev and frontend-dev to complete their first tasks
   - Write unit tests for NotificationService
   - Write component tests for NotificationBell and NotificationPanel
   - Write integration test for the full notification flow
   - Verify all existing tests still pass

# Done Criteria

- [ ] notifications table exists with correct schema, RLS, and index
- [ ] All 3 REST endpoints return correct responses
- [ ] Socket.IO emits notification:new when notification is created
- [ ] NotificationBell shows unread count, updates in real-time
- [ ] NotificationPanel lists notifications, mark-as-read works
- [ ] All new tests pass: `cd backend && npm test`, `cd frontend && npm test`
- [ ] All existing tests still pass (same commands)
- [ ] No TypeScript errors: `cd frontend && npx tsc --noEmit`, `cd backend && npx tsc --noEmit`

# Rules of Engagement

- Do NOT stop until all done criteria are met (except pre-flight failure)
- If you encounter an error, debug and fix it — do not ask the user
- If teammates' work conflicts, the lead resolves immediately
- Commit work incrementally
- Follow all coding conventions from the Project Context section
- Do not over-engineer or add features not specified above
- Clean up any temporary files when done
</example-prompt>

**Why this works:**
- Clear file boundaries prevent conflicts
- Backend goes first on migration (frontend can start UI in parallel)
- Test engineer waits for implementers, then validates everything
- Pre-flight catches Supabase access issues before any work begins

---

## Example 2: Bug Investigation (Investigate Then Divide)

**Scenario:** Users report that search results sometimes show stale data. React + Node + Redis cache. No MCP tools needed.

**Why this pattern:** The root cause is unknown. Need investigation before fixing.

<example-prompt>
# Mission Brief

Users report stale search results — after updating their profile, search still shows old data for several minutes. Investigate the root cause across the cache layer, API, and frontend, then fix it.

# Project Context

(... embedded tech stack, conventions, relevant architecture docs ...)

Search flow: Frontend calls GET /search?q=term → Backend checks Redis cache (TTL 5min) → if miss, queries PostgreSQL → returns results

Relevant files:
- `src/services/search.service.ts` — search logic + cache
- `src/services/cache.service.ts` — Redis wrapper
- `src/controllers/search.controller.ts` — REST endpoint
- `frontend/src/hooks/useSearch.ts` — client-side search with debounce
- `frontend/src/pages/SearchPage.tsx` — UI

# Task Specification

Find and fix why search results show stale data after profile updates. The fix should ensure that when a user updates their profile, subsequent searches reflect the change within a reasonable time (under 10 seconds).

# Agent Team Instructions

Use Pattern D (Investigate Then Divide). Create a team with 3 members:

1. **investigator** — Read-only investigation role
   - Use Explore sub-agents to trace the search flow end-to-end
   - Check: Does profile update invalidate any cache keys?
   - Check: Is there a race condition between update and cache refresh?
   - Check: Does the frontend cache responses client-side?
   - Check: Is the Redis TTL appropriate or is there a stale-while-revalidate issue?
   - Create detailed findings report as a task list for the fixers
   - Message the team lead with root cause analysis before fixers begin

2. **backend-fixer** — Owns: `src/services/`, `src/controllers/`
   - Wait for investigator findings
   - Implement the backend portion of the fix (cache invalidation, TTL adjustment, etc.)
   - DO NOT edit frontend files

3. **frontend-fixer** — Owns: `frontend/src/`
   - Wait for investigator findings
   - Implement the frontend portion if needed (clear client cache, refetch, etc.)
   - DO NOT edit backend files

# Done Criteria

- [ ] Root cause identified and documented in commit message
- [ ] Fix implemented — profile updates reflected in search within 10 seconds
- [ ] Regression test added covering this scenario
- [ ] All existing tests pass
- [ ] No stale data observable in manual flow verification

# Rules of Engagement

- Do NOT stop until all done criteria are met
- Investigator must complete analysis BEFORE fixers begin
- If root cause is only backend or only frontend, the unused fixer reports "no changes needed"
- Debug and fix errors autonomously — do not ask the user
- Commit incrementally
</example-prompt>

**Why this works:**
- Investigation phase prevents blind guessing
- Clear handoff: investigator creates the task list
- Fixers have non-overlapping ownership
- Done criteria are specific and measurable (10-second threshold)

---

## Example 3: Database Migration + API (Sequential Pipeline)

**Scenario:** Adding a new "teams" feature. Database schema must exist before API, and API before frontend. Supabase MCP available.

**Why this pattern:** Strong dependency chain — each layer depends on the previous one being complete.

<example-prompt>
# Mission Brief

Add a teams feature allowing users to create teams of 2-4 players for team-based matches. Teams have a name, avatar, and rating. Players can belong to one team at a time.

# Pre-Flight Check

Verify Supabase access:
1. Run `list_tables` — confirm you can see existing tables
2. Run `execute_sql` with `SELECT current_user` — confirm write access

If either fails, STOP and report. Otherwise say "Pre-flight passed" and proceed.

# Project Context

(... embedded conventions, existing schema overview, API patterns ...)

# Agent Team Instructions

Use Pattern C (Sequential Pipeline). Create a team with 3 members:

1. **db-architect** — Owns: `supabase/migrations/`, schema design
   - Design and apply migration: teams table, team_members join table, team_ratings
   - Add RLS policies
   - Add foreign keys and indexes
   - When migration is applied and verified, message api-dev to begin

2. **api-dev** — Owns: `src/teams/` (new module)
   - Wait for db-architect to confirm schema is ready
   - Create TeamsModule: controller, service, DTOs
   - Endpoints: POST /teams, GET /teams/:id, POST /teams/:id/join, DELETE /teams/:id/leave
   - When endpoints are working, message frontend-dev to begin

3. **frontend-dev** — Owns: `frontend/src/pages/TeamsPage.tsx`, `frontend/src/components/teams/`
   - Wait for api-dev to confirm endpoints are ready
   - Create TeamsPage with create/join/leave flows
   - Create TeamCard, TeamList, CreateTeamModal components
   - Wire up to API using existing api client patterns

(... done criteria, rules of engagement ...)
</example-prompt>

**Why this works:**
- Explicit "message X when ready" creates the handoff chain
- Each teammate waits for dependencies instead of guessing
- File boundaries are completely non-overlapping

---

## Example 4: Research-Heavy Task (Research First, Then Implement)

**Scenario:** User wants to optimize build performance. Unknown where the bottlenecks are. No MCP tools needed.

**Why this pattern:** Need to understand the problem before knowing what to fix.

<example-prompt>
# Mission Brief

The frontend build takes over 2 minutes. Investigate where time is spent and optimize to under 45 seconds.

# Project Context

(... embedded build config, webpack/vite config, package.json dependencies ...)

# Task Specification

The coding agent should first use Explore sub-agents to research the build pipeline before creating an implementation team.

## Phase 1 — Research (before creating team)

Spawn 3 Explore sub-agents in parallel:
1. Analyze bundle size: check for large dependencies, tree-shaking opportunities
2. Analyze build config: check for missing optimizations, unnecessary plugins, source map settings
3. Profile build time: run the build with timing flags, identify slowest steps

Synthesize findings into a prioritized list of optimizations.

## Phase 2 — Implement (create team)

Based on Phase 1 findings, create a team of 2-3 specialists to implement the top optimizations in parallel. Assign file boundaries based on what needs changing.

(... done criteria: build time under 45s, all tests pass, no functionality regression ...)
</example-prompt>

**Why this works:**
- Sub-agents do cheap, parallel research before committing to a team structure
- Team composition is data-driven, not guessed upfront
- Clear success metric (45s threshold)

---

## Example 5: Large Feature (Multi-Prompt Sequence) — 3 Prompts

**Scenario:** User wants to build a full tournament system: database + bracket engine + matchmaking + UI + real-time updates. Too large for one prompt — touches 25+ files across 5 modules.

**Why multi-prompt:** The scope is massive. A single prompt would exhaust context and produce sloppy work near the end. Natural split: foundation (schema + core logic), gameplay (matchmaking + brackets), and UI (pages + real-time).

**Split rationale presented to user:**

    This task is too large for a single prompt. I recommend splitting into 3 sequential prompts:

    1. **Prompt 1 — Foundation** (DB + Core API): Schema, models, basic CRUD endpoints, tests
    2. **Prompt 2 — Gameplay Engine** (Logic + Matchmaking): Bracket generation, round progression, matchmaking queue, rating integration
    3. **Prompt 3 — Frontend + Real-time** (UI + WebSockets): Tournament pages, bracket visualization, live updates

    Each prompt produces a working, testable increment. Run them in order in the same chat.

<example-prompt>
## Execution Guide

This task is split into 3 sequential prompts. Run them in order in the SAME chat session.
Each prompt is fully self-contained — paste it as-is.
Wait for each prompt to complete before pasting the next one.

1. **Prompt 1 — Foundation:** Database schema, core tournament model, basic CRUD API, unit tests
2. **Prompt 2 — Gameplay Engine:** Bracket logic, round progression, matchmaking, rating integration
3. **Prompt 3 — Frontend + Real-time:** Tournament pages, bracket visualization, Socket.IO live updates

---

## Sequence: Prompt 1 of 3 — Foundation

### What previous prompts completed: Nothing — this is the first prompt.
### What this prompt will do: Create the database schema, core tournament service, and basic CRUD endpoints with tests.

# Mission Brief

Build the data foundation for a tournament system. This prompt creates the database tables, the core NestJS module with CRUD operations, and unit tests. The next prompts will add gameplay logic and frontend.

# Pre-Flight Check

1. Supabase: Run `list_tables` to confirm database access
2. Supabase: Run `execute_sql` with `SELECT 1` to confirm query access

If either fails, STOP and report. Otherwise proceed.

# Project Context

(... full embedded conventions, tech stack, file naming, testing patterns ...)

# Task Specification

## Database (Supabase migrations)
- `tournaments` table: id, name, creator_id (FK profiles), status (enum: registration, in_progress, completed, cancelled), format (enum: single_elimination, double_elimination), max_players (int), current_round (int), time_control, created_at, started_at, completed_at
- `tournament_participants` table: id, tournament_id (FK), user_id (FK), seed (int nullable), eliminated (boolean), joined_at
- RLS: anyone can read tournaments, only creator can update, participants can read their own participation
- Indexes: tournaments(status, created_at), tournament_participants(tournament_id, user_id)

## Backend (NestJS module)
- TournamentModule: controller, service, DTOs
- Endpoints: POST /tournaments (create), GET /tournaments (list active), GET /tournaments/:id (detail), POST /tournaments/:id/join, DELETE /tournaments/:id/leave, PATCH /tournaments/:id/start (creator only)
- Validation: max_players between 4 and 64, can't join if full, can't join twice, only creator can start

## Tests
- Unit tests for TournamentService (create, join, leave, start validations)
- At least 8 test cases covering happy paths and edge cases

# Agent Team Instructions

Use Pattern C (Sequential Pipeline). Create a team with 3 members:

1. **db-architect** — Owns: `supabase/migrations/`
   - Create migration for tournaments and tournament_participants tables
   - Add RLS policies and indexes
   - Verify migration with `execute_sql` queries
   - Message api-dev when schema is ready

2. **api-dev** — Owns: `connect-four-api/src/tournament/`
   - Wait for db-architect confirmation
   - Create TournamentModule with controller, service, DTOs
   - Implement all 6 endpoints with validation
   - DO NOT touch frontend or database migration files

3. **test-dev** — Owns: `connect-four-api/src/tournament/*.spec.ts`
   - Wait for api-dev to complete the service
   - Write comprehensive unit tests for TournamentService
   - Verify all existing backend tests still pass

# Done Criteria

- [ ] Both tables exist with correct schema, RLS, and indexes
- [ ] All 6 endpoints respond correctly (test with manual curl or service tests)
- [ ] At least 8 unit tests for TournamentService, all passing
- [ ] All existing backend tests pass: `cd connect-four-api && npx jest`
- [ ] No TypeScript errors: `cd connect-four-api && npx tsc --noEmit`

# Rules of Engagement

- Do NOT stop until all done criteria are met
- Debug and fix errors autonomously
- Commit work incrementally with descriptive messages
- Follow all coding conventions from Project Context
- Do not add gameplay logic (brackets, rounds) — that's Prompt 2

# Handoff Note

The next prompt (Prompt 2) will add bracket generation, round progression, and matchmaking. Ensure all endpoints are working and the tournament service is well-structured for extension. The service will need new methods added in Prompt 2 — keep the code clean and extensible.

---

## Sequence: Prompt 2 of 3 — Gameplay Engine

### What previous prompts completed: Database schema (tournaments + participants tables), basic CRUD API (create, list, detail, join, leave, start), unit tests.
### What this prompt will do: Add bracket generation, round progression, matchmaking queue, and rating integration.

# Mission Brief

Add the gameplay engine to the tournament system. This prompt implements bracket generation (seeding, pairing), round-by-round progression, a matchmaking queue that creates games between paired players, and rating updates on tournament completion.

# Pre-Flight Check

1. Supabase: Run `list_tables` — confirm `tournaments` and `tournament_participants` tables exist
2. Supabase: Run `execute_sql` with `SELECT count(*) FROM tournaments` — confirm previous migration applied
3. Run `cd connect-four-api && npx jest --testPathPattern=tournament` — confirm previous tests pass

If any check fails, STOP and tell the user to re-run Prompt 1.

# Project Context

(... full embedded conventions again — same as Prompt 1 ...)

# Task Specification

(... detailed bracket logic, matchmaking queue, rating integration specs ...)

# Agent Team Instructions

Use Pattern B (Parallel Specialists). Create a team with 3 members:

1. **bracket-dev** — Owns: `connect-four-api/src/tournament/bracket.service.ts`, `connect-four-api/src/tournament/bracket.utils.ts`
   (... tasks ...)

2. **matchmaking-dev** — Owns: `connect-four-api/src/tournament/matchmaking.service.ts`, `connect-four-api/src/tournament/tournament.gateway.ts`
   (... tasks ...)

3. **test-dev** — Owns: `connect-four-api/src/tournament/*.spec.ts` (new test files only)
   (... tasks ...)

(... done criteria, rules, handoff note for Prompt 3 ...)

---

## Sequence: Prompt 3 of 3 — Frontend + Real-time

### What previous prompts completed: Database schema, CRUD API, bracket engine, matchmaking queue, rating integration, all backend tests passing.
### What this prompt will do: Build tournament pages, bracket visualization, and real-time updates via Socket.IO.

# Mission Brief

Build the frontend for the tournament system. Tournament list page, tournament detail page with bracket visualization, join/leave flows, and real-time updates when matches complete and brackets advance.

# Pre-Flight Check

1. Run `cd connect-four-api && npx jest` — confirm ALL backend tests pass
2. Supabase: Run `execute_sql` with `SELECT count(*) FROM tournaments` — confirm tables exist
3. Run `cd connect-four-app && npx vitest run` — confirm existing frontend tests pass

If any check fails, STOP and tell the user to re-run previous prompts.

# Project Context

(... full embedded conventions again — including CSS variables, component patterns, etc. ...)

(... task spec, team instructions, done criteria, rules ...)
</example-prompt>

**Why this works:**
- Each prompt produces a working increment (schema → logic → UI)
- Prompt 2 and 3 verify previous work before starting
- Project Context is re-embedded in every prompt (fresh session, zero memory)
- Handoff Notes tell each prompt what the next one expects
- The execution guide at the top gives the user a clear roadmap

---

## Example 6: Migration + Rebuild (Multi-Prompt, Design Then Build) — 2 Prompts

**Scenario:** User wants to replace the existing auth system (Passport.js) with Supabase Auth. This is risky — need to design first, then execute.

**Why multi-prompt:** Ripping out auth without a plan is dangerous. Prompt 1 investigates the current system and produces a migration plan. Prompt 2 executes it. The user can review the plan between prompts.

**Split rationale:**

    This is a risky migration. I recommend 2 prompts:

    1. **Prompt 1 — Investigation & Design:** Map all auth touchpoints, design migration plan, create a checklist
    2. **Prompt 2 — Execute Migration:** Implement the plan from Prompt 1

    You can review the migration plan between Prompt 1 and Prompt 2 before committing to execution.

<example-prompt>
## Execution Guide

This migration is split into 2 prompts. Run them in order in the SAME chat.
**Important:** Review the migration plan output from Prompt 1 before pasting Prompt 2.

1. **Prompt 1 — Investigation & Design:** Maps every auth touchpoint, produces a migration plan file
2. **Prompt 2 — Execute Migration:** Implements the plan, swaps auth, updates all touchpoints, tests

---

## Sequence: Prompt 1 of 2 — Investigation & Design

### What previous prompts completed: Nothing — this is the first prompt.
### What this prompt will do: Investigate every auth touchpoint in the codebase and produce a detailed migration plan document.

# Mission Brief

Map every file that touches authentication in this project — guards, middleware, login/signup flows, token storage, protected routes, session handling. Produce a migration plan document at `docs/auth-migration-plan.md` that lists every file to change, what changes are needed, the order of operations, and rollback steps.

# Project Context

(... embedded conventions, current auth architecture ...)

# Task Specification

This is a READ-ONLY investigation prompt. Do NOT change any source code. Only create the migration plan document.

## Investigation targets:
- All files importing passport, jwt, session, cookie-related packages
- All auth guards and middleware
- All login/signup/logout endpoints and frontend pages
- All protected routes (frontend and backend)
- Environment variables related to auth
- Database tables storing user sessions or tokens

## Output: `docs/auth-migration-plan.md` containing:
- Current auth architecture summary
- Complete list of files to modify (with line numbers for key changes)
- New files to create
- Files to delete
- Migration order (what must change first)
- Rollback plan (how to revert if something breaks)
- Test plan (how to verify each step)

# Agent Team Instructions

Use Pattern D (Investigate Then Divide). Create a team with 3 members:

1. **backend-investigator** — Read all backend auth files, map guards, middleware, endpoints
2. **frontend-investigator** — Read all frontend auth files, map protected routes, token storage, login flows
3. **plan-writer** — Wait for both investigators, then synthesize into the migration plan document

# Done Criteria

- [ ] `docs/auth-migration-plan.md` exists and is comprehensive
- [ ] Every auth-related file is listed with specific changes needed
- [ ] Migration order is specified
- [ ] Rollback plan is included
- [ ] NO source code was modified (only the plan document was created)

# Handoff Note

The user will review this migration plan. Prompt 2 will execute it. Make the plan detailed enough that Prompt 2 can follow it mechanically.

---

## Sequence: Prompt 2 of 2 — Execute Migration

### What previous prompts completed: A migration plan at `docs/auth-migration-plan.md` mapping every auth touchpoint and specifying the change order.
### What this prompt will do: Execute the migration plan — replace Passport.js auth with Supabase Auth across the entire codebase.

# Mission Brief

Execute the auth migration plan documented in `docs/auth-migration-plan.md`. Replace Passport.js with Supabase Auth across backend and frontend. Follow the migration order specified in the plan exactly.

# Pre-Flight Check

1. Confirm `docs/auth-migration-plan.md` exists — read it to understand the full scope
2. Supabase: Run `list_tables` — confirm database access
3. Run all tests to establish baseline: backend and frontend test commands
4. Verify git is clean: `git status` — commit or stash any uncommitted work

If the migration plan doesn't exist, STOP and tell the user to run Prompt 1 first.

# Project Context

(... full embedded conventions ...)

(... task spec referencing the plan, team instructions, done criteria, rules ...)
</example-prompt>

**Why this works:**
- The user reviews the migration plan between prompts — critical safety gate
- Prompt 1 is read-only, zero risk of breaking anything
- Prompt 2 reads the plan doc that Prompt 1 created — clean handoff via filesystem
- The investigation team and execution team have different shapes (investigators vs implementers)

---

## Example 7: Monorepo Feature (Multi-Prompt, Parallel with Isolated Tasks) — 2 Prompts + Integration

**Scenario:** A monorepo with `frontend/` (React) and `backend/` (NestJS) as separate packages. User wants to add a leaderboard feature — new API endpoint + new page. The two directories are fully independent and never import from each other.

**Why parallel:** Frontend and backend are separate packages in a monorepo. They touch completely different files. An agreed API contract lets both proceed simultaneously. An integration prompt at the end wires them together and runs E2E tests.

**Split rationale:**

    This is a monorepo with independent frontend/ and backend/ packages.
    The prompts touch zero overlapping files, so they can run in parallel.
    I recommend:

    1. **Prompt 1 — Backend:** Leaderboard API endpoint + backend tests (files: backend/src/leaderboard/)
    2. **Prompt 2 — Frontend:** Leaderboard page + components + frontend tests (files: frontend/src/pages/leaderboard/, frontend/src/components/leaderboard/)
    3. **Integration Prompt:** Wire frontend to backend, run E2E tests

    Both prompts agree on the API contract upfront. Run Prompt 1 and 2 at the same time in separate terminals.

<example-prompt>
## Execution Guide — Parallel

This task is split into 2 prompts that run **simultaneously in separate Claude Code sessions**, plus one integration prompt after both finish.

### Setup
Open 2 terminals in the project root. Run `claude` in each. Paste one prompt per session.

### Prompts (run BOTH at the same time)
1. **Prompt 1 — Backend API:** Leaderboard endpoint, service, tests | Files: `backend/src/leaderboard/`, `backend/src/app.module.ts`
2. **Prompt 2 — Frontend UI:** Leaderboard page, components, hooks, tests | Files: `frontend/src/pages/leaderboard/`, `frontend/src/components/leaderboard/`, `frontend/src/hooks/useLeaderboard.ts`

### After both prompts complete
Run the full test suite to verify no conflicts:

    cd backend && npm test
    cd frontend && npm test

Then paste the Integration Prompt to wire everything together.

---

## Parallel Task: Prompt 1 of 2 — Backend API

### Execution mode: PARALLEL — this prompt runs independently alongside Prompt 2
### This prompt's file boundaries: `backend/src/leaderboard/`, `backend/src/app.module.ts` (import only)
### What this prompt will do: Create the leaderboard API endpoint with service, DTOs, and tests
### DO NOT touch these files (owned by Prompt 2): anything in `frontend/`

# Mission Brief

Build the backend for a leaderboard feature. Create a new NestJS module with an endpoint that returns the top N players ranked by rating, with filters for time period and game mode.

# Pre-Flight Check

1. Supabase: Run `list_tables` — confirm database access
2. Run `cd backend && npm test` — establish passing baseline

If either fails, STOP and report.

# Project Context

(... full embedded backend conventions, NestJS patterns, file naming ...)

Agreed API contract (Prompt 2 will build the frontend against this):
- GET /leaderboard?limit=50&period=weekly|monthly|alltime&mode=ranked|casual
- Response: { players: [{ rank, userId, username, avatarUrl, rating, gamesWon, gamesPlayed }], total }

# Task Specification

(... detailed backend spec ...)

# Agent Team Instructions

Use Pattern B (Parallel Specialists). Create a team with 2 members:

1. **api-dev** — Owns: `backend/src/leaderboard/`
   - Create LeaderboardModule, LeaderboardService, LeaderboardController
   - Implement the GET /leaderboard endpoint matching the API contract exactly
   - Add DTOs with class-validator
   - Register module in AppModule
   - DO NOT create or edit any files in `frontend/`

2. **test-dev** — Owns: `backend/src/leaderboard/*.spec.ts`
   - Write unit tests for LeaderboardService (mock Supabase client)
   - Test query building for each filter combination
   - Verify all existing backend tests still pass

# Done Criteria

- [ ] GET /leaderboard returns correct data matching the API contract
- [ ] Filters work: limit, period (weekly/monthly/alltime), mode (ranked/casual)
- [ ] Unit tests cover all filter combinations
- [ ] All backend tests pass: `cd backend && npm test`
- [ ] No TypeScript errors: `cd backend && npx tsc --noEmit`
- [ ] ZERO files touched in `frontend/`

# Rules of Engagement

- Do NOT stop until all done criteria are met
- Do NOT touch any files outside `backend/`
- Commit incrementally with descriptive messages
- Follow NestJS conventions from Project Context

---

## Parallel Task: Prompt 2 of 2 — Frontend UI

### Execution mode: PARALLEL — this prompt runs independently alongside Prompt 1
### This prompt's file boundaries: `frontend/src/pages/leaderboard/`, `frontend/src/components/leaderboard/`, `frontend/src/hooks/useLeaderboard.ts`
### What this prompt will do: Create the leaderboard page, components, and frontend tests
### DO NOT touch these files (owned by Prompt 1): anything in `backend/`

# Mission Brief

Build the frontend for a leaderboard feature. Create a new page with a ranked player table, time period tabs, and game mode filter. Build against the agreed API contract — the backend is being built simultaneously by another agent.

# Project Context

(... full embedded frontend conventions, component patterns, CSS variables ...)

Agreed API contract (build against this — the backend will match it):
- GET /leaderboard?limit=50&period=weekly|monthly|alltime&mode=ranked|casual
- Response: { players: [{ rank, userId, username, avatarUrl, rating, gamesWon, gamesPlayed }], total }

# Task Specification

(... detailed frontend spec ...)

# Agent Team Instructions

(... frontend-only team: ui-dev + test-dev ...)

# Done Criteria

- [ ] Leaderboard page renders with player table
- [ ] Time period tabs work (weekly/monthly/alltime)
- [ ] Game mode filter works (ranked/casual)
- [ ] Component tests pass
- [ ] All frontend tests pass: `cd frontend && npm test`
- [ ] ZERO files touched in `backend/`

# Rules of Engagement

- Do NOT stop until all done criteria are met
- Do NOT touch any files outside `frontend/`
- The backend endpoint doesn't exist yet — mock the API response in tests using the agreed contract
- Commit incrementally

---

## Integration Prompt (run AFTER both parallel prompts complete)

# Mission Brief

Wire the leaderboard frontend to the leaderboard backend and verify everything works end-to-end.

# Pre-Flight Check

1. Verify backend: `cd backend && npm test` — all tests pass including new leaderboard tests
2. Verify frontend: `cd frontend && npm test` — all tests pass including new leaderboard tests
3. Verify endpoint exists: Run `curl http://localhost:3001/leaderboard?limit=5` (start backend if needed)

If any check fails, STOP and report which parallel prompt needs to be re-run.

# Project Context

(... embedded conventions ...)

# Task Specification

1. Remove any API mocks from frontend leaderboard tests — replace with real API client calls
2. Verify the frontend's API client correctly hits the backend endpoint
3. Fix any mismatches between the frontend's expected response shape and the backend's actual response
4. Run both test suites to confirm everything passes
5. If available, run Playwright E2E test: navigate to /leaderboard, verify data renders

# Done Criteria

- [ ] Frontend leaderboard page successfully calls backend API
- [ ] No API mocks remain in production code (test mocks are fine)
- [ ] All backend tests pass
- [ ] All frontend tests pass
- [ ] Leaderboard page renders real data when both servers are running
</example-prompt>

**Why this works:**
- Backend and frontend are fully isolated — zero file overlap
- Both prompts agree on an API contract upfront (the "interface" between them)
- Frontend mocks the API during development, integration prompt removes mocks
- The execution guide gives clear terminal setup instructions
- Integration prompt catches any contract mismatches after both are done

---

## Tips on Code Blocks in Prompts

Since the generated prompt is markdown that gets pasted directly into a chat, triple backticks will break formatting. Use these alternatives:

**For inline code:** single backticks work fine — `like this`

**For multi-line code examples, use XML tags:**

<code-example lang="typescript">
interface Team {
  id: string;
  name: string;
  members: string[];
}
</code-example>

**Or use 4-space indentation:**

    interface Team {
      id: string;
      name: string;
      members: string[];
    }

**For shell commands:** single backticks or XML tags:

<code-example lang="bash">
npm run test
npm run build
</code-example>
