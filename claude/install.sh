#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${HOME}/.claude"
FORCE=false
SCAFFOLD=false
STACKS=""

# --- Parse arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --stacks)
            STACKS="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --scaffold)
            SCAFFOLD=true
            shift
            ;;
        -h|--help)
            echo "Usage: claude/install.sh [--stacks nestjs,python] [--force] [--scaffold]"
            echo ""
            echo "Options:"
            echo "  --stacks    Comma-separated stack packs to install (interactive if omitted)"
            echo "  --force     Overwrite existing files without prompting"
            echo "  --scaffold  Also copy docs-scaffold/ (use with a project directory)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=== Claude Skills Global Installer ==="
echo "Source: ${SCRIPT_DIR}"
echo "Target: ${CLAUDE_HOME}"
echo ""

# --- Helper: copy with overwrite prompt ---
copy_item() {
    local src="$1" target="$2" name="$3"
    if [[ -e "${target}" ]]; then
        if [[ "${FORCE}" == true ]]; then
            rm -rf "${target}"
            cp -r "${src}" "${target}"
            echo "  Updated: ${name}"
        else
            read -p "  ${name} already exists. Overwrite? [y/N]: " answer
            if [[ "${answer}" =~ ^[Yy]$ ]]; then
                rm -rf "${target}"
                cp -r "${src}" "${target}"
                echo "  Updated: ${name}"
            else
                echo "  SKIP: ${name}"
            fi
        fi
    else
        cp -r "${src}" "${target}"
        echo "  Copied: ${name}"
    fi
}

# --- Step 1: Create directories ---
mkdir -p "${CLAUDE_HOME}/skills"
mkdir -p "${CLAUDE_HOME}/agents"

# --- Step 2: Copy shared skills ---
echo "Skills:"
for skill_dir in "${SCRIPT_DIR}/skills"/*/; do
    skill_name="$(basename "${skill_dir}")"

    if [[ "${skill_name}" == "_template" ]]; then
        continue
    fi

    target="${CLAUDE_HOME}/skills/${skill_name}"
    copy_item "${skill_dir}" "${target}" "${skill_name}"
done

# --- Step 3: Copy shared agents ---
echo ""
echo "Agents:"
for agent_file in "${SCRIPT_DIR}/agents"/*.md; do
    agent_name="$(basename "${agent_file}")"
    target="${CLAUDE_HOME}/agents/${agent_name}"
    copy_item "${agent_file}" "${target}" "${agent_name}"
done

# --- Step 4: Install stack-specific skills ---
echo ""
echo "Available stack packs:"
for stack_dir in "${SCRIPT_DIR}/stacks"/*/; do
    if [[ -d "${stack_dir}" ]]; then
        echo "  - $(basename "${stack_dir}")"
    fi
done

if [[ -z "${STACKS}" ]]; then
    echo ""
    read -p "Install stack packs (comma-separated, e.g., 'nestjs,python' or 'none'): " STACKS
fi

if [[ "${STACKS}" != "none" && -n "${STACKS}" ]]; then
    IFS=',' read -ra STACK_ARRAY <<< "${STACKS}"
    for stack in "${STACK_ARRAY[@]}"; do
        stack="$(echo "${stack}" | xargs)"  # trim whitespace
        stack_src="${SCRIPT_DIR}/stacks/${stack}"

        if [[ ! -d "${stack_src}" ]]; then
            echo "  WARNING: Stack '${stack}' not found, skipping"
            continue
        fi

        target="${CLAUDE_HOME}/skills/${stack}"
        copy_item "${stack_src}" "${target}" "${stack}"
    done
fi

# --- Step 6: Optionally scaffold docs/ ---
if [[ "${SCAFFOLD}" == true ]]; then
    SCAFFOLD_DIR="${SCRIPT_DIR}/../docs-scaffold"
    echo ""
    echo "Docs scaffold:"
    if [[ -d "${SCAFFOLD_DIR}" ]]; then
        echo "  docs-scaffold/ available at: ${SCAFFOLD_DIR}"
        echo "  Copy it manually to your project: cp -r '${SCAFFOLD_DIR}' /path/to/project/docs"
    else
        echo "  WARNING: docs-scaffold/ not found"
    fi
fi

echo ""
echo "=== Installation complete ==="
echo ""
echo "Installed to ${CLAUDE_HOME}:"
echo "  Skills:   $(ls -1 "${CLAUDE_HOME}/skills/" 2>/dev/null | wc -l | xargs) items"
echo "  Agents:   $(ls -1 "${CLAUDE_HOME}/agents/" 2>/dev/null | wc -l | xargs) items"
echo ""
echo "To update: cd $(dirname "${SCRIPT_DIR}") && git pull && ./install.sh --tool claude"
