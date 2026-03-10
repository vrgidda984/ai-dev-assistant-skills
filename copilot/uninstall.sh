#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}"

# --- Parse arguments ---
TARGET_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            TARGET_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: copilot/uninstall.sh --target <project-dir>"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [[ -z "${TARGET_DIR}" ]]; then
    echo "Error: --target is required"
    echo "Usage: copilot/uninstall.sh --target <project-dir>"
    exit 1
fi

TARGET_DIR="$(cd "${TARGET_DIR}" && pwd)"
GITHUB_DIR="${TARGET_DIR}/.github"

echo "=== Copilot Skills Uninstaller ==="
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

echo "Removing prompts..."
remove_matching_items "${GITHUB_DIR}/prompts" "${SOURCE_DIR}/prompts"

echo ""
echo "Removing agents..."
remove_matching_items "${GITHUB_DIR}/agents" "${SOURCE_DIR}/agents"

echo ""
echo "Removing instructions..."
remove_matching_items "${GITHUB_DIR}/instructions" "${SOURCE_DIR}/instructions"

echo ""
echo "Checking copilot-instructions.md..."
if [[ -f "${GITHUB_DIR}/copilot-instructions.md" ]]; then
    read -p "  Remove copilot-instructions.md? [y/N]: " answer
    if [[ "${answer}" =~ ^[Yy]$ ]]; then
        rm "${GITHUB_DIR}/copilot-instructions.md"
        echo "  Removed: copilot-instructions.md"
    else
        echo "  SKIP: copilot-instructions.md"
    fi
fi

echo ""
echo "=== Uninstall complete ==="
echo "Only items matching this repo's contents were removed (with your confirmation)."
