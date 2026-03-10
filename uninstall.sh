#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Parse --tool flag, pass everything else through ---
TOOL=""
PASSTHROUGH_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tool)
            TOOL="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: uninstall.sh --tool <claude|copilot> [tool-specific options]"
            echo ""
            echo "Options:"
            echo "  --tool      AI assistant to uninstall: 'claude' or 'copilot' (interactive if omitted)"
            echo ""
            echo "Copilot options: --target <dir>"
            exit 0
            ;;
        *)
            PASSTHROUGH_ARGS+=("$1")
            shift
            ;;
    esac
done

echo "=== AI Dev Assistant Skills Uninstaller ==="
echo ""

if [[ -z "${TOOL}" ]]; then
    echo "Which AI assistant are you uninstalling?"
    echo "  1) Claude Code"
    echo "  2) GitHub Copilot"
    echo ""
    read -p "Choose [1/2]: " choice
    case "${choice}" in
        1) TOOL="claude" ;;
        2) TOOL="copilot" ;;
        *)
            echo "Invalid choice. Use 1 (Claude) or 2 (Copilot)."
            exit 1
            ;;
    esac
fi

case "${TOOL}" in
    claude)
        exec "${SCRIPT_DIR}/claude/uninstall.sh" "${PASSTHROUGH_ARGS[@]+"${PASSTHROUGH_ARGS[@]}"}"
        ;;
    copilot)
        exec "${SCRIPT_DIR}/copilot/uninstall.sh" "${PASSTHROUGH_ARGS[@]+"${PASSTHROUGH_ARGS[@]}"}"
        ;;
    *)
        echo "Unknown tool: ${TOOL}. Use 'claude' or 'copilot'."
        exit 1
        ;;
esac
