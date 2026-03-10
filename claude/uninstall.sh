#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${HOME}/.claude"

echo "=== Claude Skills Uninstaller ==="
echo ""

# Remove items that match names in this repo
remove_matching_items() {
    local target_dir="$1" source_dir="$2"
    if [[ ! -d "${target_dir}" || ! -d "${source_dir}" ]]; then
        return
    fi

    for source_item in "${source_dir}"/*; do
        local name
        name="$(basename "${source_item}")"
        local target="${target_dir}/${name}"

        if [[ "${name}" == "_template" ]]; then
            continue
        fi

        if [[ -e "${target}" ]]; then
            read -p "  Remove ${name}? [y/N]: " answer
            if [[ "${answer}" =~ ^[Yy]$ ]]; then
                rm -rf "${target}"
                echo "  Removed: ${name}"
            else
                echo "  SKIP: ${name}"
            fi
        fi
    done
}

echo "Removing skills..."
remove_matching_items "${CLAUDE_HOME}/skills" "${SCRIPT_DIR}/skills"

echo ""
echo "Removing stack skills..."
remove_matching_items "${CLAUDE_HOME}/skills" "${SCRIPT_DIR}/stacks"

echo ""
echo "Removing agents..."
remove_matching_items "${CLAUDE_HOME}/agents" "${SCRIPT_DIR}/agents"

echo ""
echo "Removing commands..."
remove_matching_items "${CLAUDE_HOME}/commands" "${SCRIPT_DIR}/commands"

echo ""
echo "=== Uninstall complete ==="
echo "Only items matching this repo's contents were removed (with your confirmation)."
