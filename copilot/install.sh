#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}"

# --- Parse arguments ---
TARGET_DIR=""
STACKS=""
FORCE=false
SCAFFOLD=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            TARGET_DIR="$2"
            shift 2
            ;;
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
            echo "Usage: copilot/install.sh --target <project-dir> [--stacks nestjs,python] [--force] [--scaffold]"
            echo ""
            echo "Options:"
            echo "  --target    Project directory to install into (required)"
            echo "  --stacks    Comma-separated stack packs to install (interactive if omitted)"
            echo "  --force     Overwrite existing files without prompting"
            echo "  --scaffold  Also copy docs-scaffold/ to docs/ in the target project"
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
    echo "Usage: copilot/install.sh --target <project-dir> [--stacks nestjs,python] [--force] [--scaffold]"
    exit 1
fi

TARGET_DIR="$(cd "${TARGET_DIR}" && pwd)"
GITHUB_DIR="${TARGET_DIR}/.github"

echo "=== Copilot Skills Installer ==="
echo "Source: ${SCRIPT_DIR}"
echo "Target: ${GITHUB_DIR}"
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
mkdir -p "${GITHUB_DIR}/prompts"
mkdir -p "${GITHUB_DIR}/agents"
mkdir -p "${GITHUB_DIR}/instructions"

# --- Step 2: Copy copilot-instructions.md ---
echo "Global instructions:"
if [[ -f "${GITHUB_DIR}/copilot-instructions.md" ]]; then
    if [[ "${FORCE}" == true ]]; then
        cp "${SOURCE_DIR}/copilot-instructions.md" "${GITHUB_DIR}/copilot-instructions.md"
        echo "  Updated: copilot-instructions.md"
    else
        echo "  copilot-instructions.md already exists."
        read -p "  Overwrite, append, or skip? [o/a/S]: " answer
        case "${answer}" in
            [Oo])
                cp "${SOURCE_DIR}/copilot-instructions.md" "${GITHUB_DIR}/copilot-instructions.md"
                echo "  Updated: copilot-instructions.md"
                ;;
            [Aa])
                echo "" >> "${GITHUB_DIR}/copilot-instructions.md"
                echo "<!-- === BEGIN: copilot-skills shared standards === -->" >> "${GITHUB_DIR}/copilot-instructions.md"
                cat "${SOURCE_DIR}/copilot-instructions.md" >> "${GITHUB_DIR}/copilot-instructions.md"
                echo "<!-- === END: copilot-skills shared standards === -->" >> "${GITHUB_DIR}/copilot-instructions.md"
                echo "  Appended: copilot-instructions.md"
                ;;
            *)
                echo "  SKIP: copilot-instructions.md"
                ;;
        esac
    fi
else
    cp "${SOURCE_DIR}/copilot-instructions.md" "${GITHUB_DIR}/copilot-instructions.md"
    echo "  Copied: copilot-instructions.md"
fi

# --- Step 3: Copy prompts ---
echo ""
echo "Prompts:"
for prompt_file in "${SOURCE_DIR}/prompts"/*.prompt.md; do
    prompt_name="$(basename "${prompt_file}")"
    target="${GITHUB_DIR}/prompts/${prompt_name}"
    copy_item "${prompt_file}" "${target}" "${prompt_name}"
done

# --- Step 4: Copy agents ---
echo ""
echo "Agents:"
for agent_file in "${SOURCE_DIR}/agents"/*.agent.md; do
    agent_name="$(basename "${agent_file}")"
    target="${GITHUB_DIR}/agents/${agent_name}"
    copy_item "${agent_file}" "${target}" "${agent_name}"
done

# --- Step 5: Install stack-specific instructions ---
echo ""
echo "Available stack packs:"
for instr_file in "${SOURCE_DIR}/instructions"/*.instructions.md; do
    name="$(basename "${instr_file}" .instructions.md)"
    echo "${name}" | sed 's/-testing$//' | sed 's/-secrets$//'
done | sort -u | while read -r stack; do
    echo "  - ${stack}"
done

if [[ -z "${STACKS}" ]]; then
    echo ""
    read -p "Install stack packs (comma-separated, e.g., 'nestjs,python' or 'none'): " STACKS
fi

if [[ "${STACKS}" != "none" && -n "${STACKS}" ]]; then
    echo ""
    echo "Stack instructions:"
    IFS=',' read -ra STACK_ARRAY <<< "${STACKS}"
    for stack in "${STACK_ARRAY[@]}"; do
        stack="$(echo "${stack}" | xargs)"

        found=false
        for instr_file in "${SOURCE_DIR}/instructions/${stack}"*.instructions.md; do
            if [[ -f "${instr_file}" ]]; then
                found=true
                instr_name="$(basename "${instr_file}")"
                target="${GITHUB_DIR}/instructions/${instr_name}"
                copy_item "${instr_file}" "${target}" "${instr_name}"
            fi
        done

        if [[ "${found}" == false ]]; then
            echo "  WARNING: No instructions found for stack '${stack}', skipping"
        fi
    done
fi

# --- Step 6: Optionally scaffold docs/ ---
if [[ "${SCAFFOLD}" == true ]]; then
    echo ""
    echo "Docs scaffold:"
    SCAFFOLD_SRC="${SCRIPT_DIR}/../docs-scaffold"
    if [[ -d "${SCAFFOLD_SRC}" ]]; then
        DOCS_DIR="${TARGET_DIR}/docs"
        mkdir -p "${DOCS_DIR}"

        for item in "${SCAFFOLD_SRC}"/*; do
            name="$(basename "${item}")"
            target="${DOCS_DIR}/${name}"
            if [[ -e "${target}" ]]; then
                echo "  SKIP (exists): docs/${name}"
            else
                cp -r "${item}" "${target}"
                echo "  Copied: docs/${name}"
            fi
        done
    else
        echo "  WARNING: docs-scaffold/ not found"
    fi
fi

# --- Summary ---
echo ""
echo "=== Installation complete ==="
echo ""
echo "Installed to ${GITHUB_DIR}:"
echo "  Instructions: $(ls -1 "${GITHUB_DIR}/instructions/" 2>/dev/null | wc -l | xargs) files"
echo "  Prompts:      $(ls -1 "${GITHUB_DIR}/prompts/" 2>/dev/null | wc -l | xargs) files"
echo "  Agents:       $(ls -1 "${GITHUB_DIR}/agents/" 2>/dev/null | wc -l | xargs) files"
echo ""
echo "To update: cd $(dirname "${SCRIPT_DIR}") && git pull && ./install.sh --tool copilot --target ${TARGET_DIR}"
