#!/bin/bash
# validate-prompt.sh
# Validates that a generated agent team prompt is well-formed markdown
# ready for copy-paste into a fresh Claude Code session.
#
# Usage:
#   bash validate-prompt.sh <file.md>        # validate a file
#   bash validate-prompt.sh <<< "$PROMPT"    # validate from stdin
#   echo "$PROMPT" | bash validate-prompt.sh # validate from pipe

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

errors=0
warnings=0

# Read input from file arg or stdin
if [ $# -ge 1 ] && [ -f "$1" ]; then
    content=$(cat "$1")
    source_label="$1"
else
    content=$(cat)
    source_label="stdin"
fi

if [ -z "$content" ]; then
    echo -e "${RED}ERROR: Empty input — no prompt content to validate${NC}"
    exit 1
fi

line_count=$(echo "$content" | wc -l | tr -d ' ')
char_count=$(echo "$content" | wc -c | tr -d ' ')

echo "Validating prompt from: $source_label ($line_count lines, $char_count chars)"
echo "---"

# --- Detect multi-prompt sequence and execution mode ---

is_multi_prompt=false
is_parallel=false
prompt_count=$(echo "$content" | grep -ciE "^#+ .*(prompt|parallel prompt|parallel task) [0-9]+ of [0-9]+" || true)
if [ "$prompt_count" -gt 1 ]; then
    is_multi_prompt=true
    if echo "$content" | grep -qiE "parallel|simultaneously|separate.*session"; then
        is_parallel=true
        echo -e "${GREEN}[INFO]${NC} Multi-prompt PARALLEL sequence detected ($prompt_count prompts)"
    else
        echo -e "${GREEN}[INFO]${NC} Multi-prompt SEQUENTIAL sequence detected ($prompt_count prompts)"
    fi
fi

# --- Required Sections ---

check_section() {
    local section_name="$1"
    local pattern="$2"
    if echo "$content" | grep -qiE "$pattern"; then
        echo -e "${GREEN}[PASS]${NC} Section found: $section_name"
    else
        echo -e "${RED}[FAIL]${NC} Missing section: $section_name"
        ((errors++))
    fi
}

check_section "Mission Brief" "^#+ .*mission|^#+ .*brief|^#+ .*overview|^#+ .*goal"
check_section "Project Context" "^#+ .*project context|^#+ .*context|^#+ .*tech stack|^#+ .*conventions"
check_section "Task Specification" "^#+ .*task|^#+ .*specification|^#+ .*requirements|^#+ .*what to build"
check_section "Agent Team Instructions" "^#+ .*agent team|^#+ .*team instruc|^#+ .*team structure|^#+ .*team composition"
check_section "Done Criteria" "^#+ .*done|^#+ .*criteria|^#+ .*verification|^#+ .*completion|^#+ .*checklist"
check_section "Rules of Engagement" "^#+ .*rules|^#+ .*engagement|^#+ .*constraints|^#+ .*operating rules"

# --- Multi-prompt specific checks ---

if [ "$is_multi_prompt" = true ]; then
    # Check for execution guide
    if echo "$content" | grep -qiE "execution guide|run them in order|sequential prompt"; then
        echo -e "${GREEN}[PASS]${NC} Execution guide found for multi-prompt sequence"
    else
        echo -e "${YELLOW}[WARN]${NC} Multi-prompt sequence missing execution guide at the top"
        ((warnings++))
    fi

    # Check for handoff notes (sequential only — parallel prompts don't hand off to each other)
    if [ "$is_parallel" = false ]; then
        handoff_count=$(echo "$content" | grep -ciE "handoff|next prompt|the next prompt will" || true)
        expected_handoffs=$((prompt_count - 1))
        if [ "$handoff_count" -ge "$expected_handoffs" ]; then
            echo -e "${GREEN}[PASS]${NC} Handoff notes found ($handoff_count)"
        else
            echo -e "${YELLOW}[WARN]${NC} Expected at least $expected_handoffs handoff notes between prompts, found $handoff_count"
            ((warnings++))
        fi
    fi

    # Check that Project Context appears in multiple prompts
    context_count=$(echo "$content" | grep -ciE "^#+ .*project context|^#+ .*tech stack" || true)
    if [ "$context_count" -ge "$prompt_count" ]; then
        echo -e "${GREEN}[PASS]${NC} Project Context embedded in each prompt ($context_count occurrences)"
    else
        echo -e "${YELLOW}[WARN]${NC} Project Context should be in every prompt ($context_count found, $prompt_count prompts)"
        ((warnings++))
    fi

    # Check that Prompt 2+ verify previous work (sequential only)
    if [ "$is_parallel" = false ]; then
        verify_prev=$(echo "$content" | grep -ciE "previous prompt|confirm.*previous|verify.*previous|what previous prompts completed" || true)
        if [ "$verify_prev" -ge 1 ]; then
            echo -e "${GREEN}[PASS]${NC} Previous-work verification found in later prompts"
        else
            echo -e "${YELLOW}[WARN]${NC} Prompt 2+ should verify previous prompt's output in Pre-Flight Check"
            ((warnings++))
        fi
    fi
fi

# --- Parallel-specific checks ---

if [ "$is_parallel" = true ]; then
    # Check for DO NOT touch / file boundary declarations
    boundary_decl=$(echo "$content" | grep -ciE "DO NOT touch|must NOT touch|owned by other|file boundar" || true)
    if [ "$boundary_decl" -ge 2 ]; then
        echo -e "${GREEN}[PASS]${NC} Parallel file boundary declarations found ($boundary_decl)"
    else
        echo -e "${RED}[FAIL]${NC} Parallel prompts must declare exclusive file boundaries and list files NOT to touch"
        ((errors++))
    fi

    # Check for merge/integration instructions
    if echo "$content" | grep -qiE "after.*complete|merge|integration prompt|wire.*together|verify.*no conflict"; then
        echo -e "${GREEN}[PASS]${NC} Post-completion merge/integration instructions found"
    else
        echo -e "${YELLOW}[WARN]${NC} Parallel prompts should include post-completion merge or integration steps"
        ((warnings++))
    fi

    # Check for worktree or isolated task setup
    if echo "$content" | grep -qiE "worktree|separate.*terminal|separate.*session|open.*terminal"; then
        echo -e "${GREEN}[PASS]${NC} Parallel execution setup instructions found"
    else
        echo -e "${YELLOW}[WARN]${NC} Parallel prompts should include setup instructions (worktree or separate terminals)"
        ((warnings++))
    fi
fi

# --- Broken Triple Backticks ---

backtick_count=$(echo "$content" | grep -c '```' || true)
if [ "$backtick_count" -gt 0 ]; then
    if [ $((backtick_count % 2)) -ne 0 ]; then
        echo -e "${RED}[FAIL]${NC} Odd number of triple backticks ($backtick_count) — likely broken code block"
        ((errors++))
    else
        echo -e "${YELLOW}[WARN]${NC} Found $backtick_count triple backticks — these may break formatting when pasted. Consider using XML tags or 4-space indent instead."
        ((warnings++))
    fi
else
    echo -e "${GREEN}[PASS]${NC} No triple backticks (good — won't break markdown)"
fi

# --- File Boundaries Check ---

if echo "$content" | grep -qiE "owns?:|file boundar|DO NOT edit|must NOT touch"; then
    echo -e "${GREEN}[PASS]${NC} File boundaries appear to be defined"
else
    echo -e "${YELLOW}[WARN]${NC} No explicit file boundaries detected — teammates may conflict"
    ((warnings++))
fi

# --- Pre-Flight Check (only warn if MCP tools mentioned) ---

if echo "$content" | grep -qiE "supabase|playwright|datadog|mcp"; then
    if echo "$content" | grep -qiE "pre-flight|preflight|verify.*tool|test.*tool.*before|check.*access"; then
        echo -e "${GREEN}[PASS]${NC} MCP pre-flight check found"
    else
        echo -e "${YELLOW}[WARN]${NC} MCP tools mentioned but no pre-flight check section found"
        ((warnings++))
    fi
fi

# --- Self-Containment Check ---

read_file_refs=$(echo "$content" | grep -ciE "read (the )?file|read CLAUDE\.md|check the docs|see the readme|refer to .*\.md" || true)
if [ "$read_file_refs" -gt 0 ]; then
    echo -e "${YELLOW}[WARN]${NC} Found $read_file_refs references to 'read file' — prompt should embed content, not reference files"
    ((warnings++))
else
    echo -e "${GREEN}[PASS]${NC} No 'read file' references (prompt appears self-contained)"
fi

# --- Minimum Length Check ---

if [ "$line_count" -lt 30 ]; then
    echo -e "${YELLOW}[WARN]${NC} Prompt is only $line_count lines — seems short for an agent team prompt"
    ((warnings++))
elif [ "$line_count" -gt 500 ]; then
    echo -e "${YELLOW}[WARN]${NC} Prompt is $line_count lines — very long. Consider if all content is necessary"
    ((warnings++))
else
    echo -e "${GREEN}[PASS]${NC} Prompt length looks reasonable ($line_count lines)"
fi

# --- Summary ---

echo ""
echo "---"
if [ "$errors" -gt 0 ]; then
    echo -e "${RED}RESULT: $errors error(s), $warnings warning(s) — prompt needs fixes${NC}"
    exit 1
elif [ "$warnings" -gt 0 ]; then
    echo -e "${YELLOW}RESULT: 0 errors, $warnings warning(s) — prompt is usable but could be improved${NC}"
    exit 0
else
    echo -e "${GREEN}RESULT: All checks passed — prompt is ready for copy-paste${NC}"
    exit 0
fi
