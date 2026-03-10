#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "${SCRIPT_DIR}")"
CLAUDE_DIR="${REPO_DIR}/claude"
COPILOT_DIR="${REPO_DIR}/copilot"

MISSING=0
WARNINGS=0

echo "=== AI Dev Assistant Skills — Drift Check ==="
echo ""

# --- 1. Agent coverage ---
echo "Agents:"
for claude_agent in "${CLAUDE_DIR}/agents"/*.md; do
    name="$(basename "${claude_agent}" .md)"
    copilot_agent="${COPILOT_DIR}/agents/${name}.agent.md"
    if [[ -f "${copilot_agent}" ]]; then
        echo "  OK  ${name}"
    else
        echo "  MISSING  ${name} — exists in claude/ but not copilot/"
        ((MISSING++))
    fi
done

# Check reverse (Copilot agents not in Claude)
for copilot_agent in "${COPILOT_DIR}/agents"/*.agent.md; do
    name="$(basename "${copilot_agent}" .agent.md)"
    claude_agent="${CLAUDE_DIR}/agents/${name}.md"
    if [[ ! -f "${claude_agent}" ]]; then
        echo "  MISSING  ${name} — exists in copilot/ but not claude/"
        ((MISSING++))
    fi
done

# --- 2. Workflow coverage ---
echo ""
echo "Workflows:"

# Mapping: claude skill dir name -> copilot prompt file name (without .prompt.md)
declare -A WORKFLOW_MAP=(
    ["session-handoff"]="session-handoff"
    ["plan-feature"]="plan-feature"
    ["code-review"]="code-review"
    ["update-docs"]="update-docs"
    ["readme-updater"]="sync-readme"
    ["repo-init"]="repo-init"
    ["github-commit-push"]="commit-push"
    ["github-create-pr"]="create-pr"
)

# Known Copilot-only workflows (no Claude equivalent expected)
COPILOT_ONLY=("resume-session")

for claude_skill in "${!WORKFLOW_MAP[@]}"; do
    copilot_prompt="${WORKFLOW_MAP[$claude_skill]}"
    claude_path="${CLAUDE_DIR}/skills/${claude_skill}/SKILL.md"
    copilot_path="${COPILOT_DIR}/prompts/${copilot_prompt}.prompt.md"

    if [[ -f "${claude_path}" && -f "${copilot_path}" ]]; then
        echo "  OK  ${claude_skill} <-> ${copilot_prompt}"
    elif [[ ! -f "${claude_path}" ]]; then
        echo "  MISSING  ${claude_skill} — missing from claude/skills/"
        ((MISSING++))
    elif [[ ! -f "${copilot_path}" ]]; then
        echo "  MISSING  ${copilot_prompt} — missing from copilot/prompts/"
        ((MISSING++))
    fi
done

for copilot_only in "${COPILOT_ONLY[@]}"; do
    copilot_path="${COPILOT_DIR}/prompts/${copilot_only}.prompt.md"
    if [[ -f "${copilot_path}" ]]; then
        echo "  INFO  ${copilot_only} — Copilot-only (expected, no Claude equivalent)"
    else
        echo "  MISSING  ${copilot_only} — expected in copilot/prompts/ but not found"
        ((MISSING++))
    fi
done

# --- 3. Stack coverage ---
echo ""
echo "Stacks:"

for stack_dir in "${CLAUDE_DIR}/stacks"/*/; do
    if [[ ! -d "${stack_dir}" ]]; then
        continue
    fi
    stack_name="$(basename "${stack_dir}")"
    claude_count=$(find "${stack_dir}" -name "*.md" | wc -l | xargs)
    copilot_count=$(find "${COPILOT_DIR}/instructions" -name "${stack_name}*.instructions.md" 2>/dev/null | wc -l | xargs)

    if [[ "${copilot_count}" -gt 0 ]]; then
        echo "  OK  ${stack_name} (${claude_count} claude files, ${copilot_count} copilot files)"
    else
        echo "  MISSING  ${stack_name} — exists in claude/stacks/ but no copilot instructions found"
        ((MISSING++))
    fi
done

# --- 4. Staleness check (git-based) ---
echo ""
echo "Staleness:"

if command -v git &>/dev/null && git -C "${REPO_DIR}" rev-parse --git-dir &>/dev/null; then
    STALE_THRESHOLD=$((7 * 86400))  # 7 days in seconds

    for claude_skill in "${!WORKFLOW_MAP[@]}"; do
        copilot_prompt="${WORKFLOW_MAP[$claude_skill]}"
        claude_path="claude/skills/${claude_skill}/SKILL.md"
        copilot_path="copilot/prompts/${copilot_prompt}.prompt.md"

        claude_ts=$(git -C "${REPO_DIR}" log -1 --format=%ct -- "${claude_path}" 2>/dev/null || echo "0")
        copilot_ts=$(git -C "${REPO_DIR}" log -1 --format=%ct -- "${copilot_path}" 2>/dev/null || echo "0")

        if [[ "${claude_ts}" == "0" || "${copilot_ts}" == "0" ]]; then
            continue  # Skip if no git history yet
        fi

        diff=$(( claude_ts > copilot_ts ? claude_ts - copilot_ts : copilot_ts - claude_ts ))
        if [[ "${diff}" -gt "${STALE_THRESHOLD}" ]]; then
            days=$(( diff / 86400 ))
            if [[ "${claude_ts}" -gt "${copilot_ts}" ]]; then
                echo "  WARN  ${claude_skill} — claude updated ${days} days after copilot (review needed?)"
            else
                echo "  WARN  ${copilot_prompt} — copilot updated ${days} days after claude (review needed?)"
            fi
            ((WARNINGS++))
        fi
    done

    if [[ "${WARNINGS}" -eq 0 ]]; then
        echo "  No staleness warnings"
    fi
else
    echo "  (skipped — not a git repo or git not available)"
fi

# --- Summary ---
echo ""
echo "=== Summary: ${MISSING} missing, ${WARNINGS} staleness warning(s) ==="

if [[ "${MISSING}" -gt 0 ]]; then
    exit 1
fi
