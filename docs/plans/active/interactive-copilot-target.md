# Feature: Interactive project directory prompt for Copilot installer

_Created: 2026-03-15_
_Status: Complete_
_Author: Claude (with user)_

## Goal

Make `--target` interactive for the Copilot installer so users can run `./install.sh`, pick Copilot, and get prompted for the project directory — instead of getting an error.

## Context

Currently, `copilot/install.sh` requires `--target <dir>` as a mandatory CLI flag. If omitted, it immediately errors out. This breaks the interactive flow: a user running the root `./install.sh` who selects Copilot has no way to provide the target directory interactively. The Claude installer doesn't have this problem because it always targets `~/.claude/`.

## Approach

Minimal changes to two scripts. No new files, no new dependencies.

### `copilot/install.sh`
Replace the hard error when `--target` is missing with an interactive prompt that:
1. Asks the user for the project directory path
2. Validates the path exists and is a directory
3. Resolves it to an absolute path (already done on line 54 with `cd && pwd`)

### `install.sh` (root)
No changes needed — it already passes through args and delegates to `copilot/install.sh`, which will now handle the missing `--target` interactively.

## Tasks

- [x] Update `copilot/install.sh`: replace the error block (lines 48-52) with an interactive `read -p` prompt + validation loop
- [x] Update `copilot/install.sh`: update the help text to reflect `--target` is optional (interactive if omitted)
- [x] Update `install.sh` (root): update help text for Copilot options to show `--target` is optional
- [ ] Test: run `./install.sh` → pick Copilot → enter valid directory → verify install completes
- [ ] Test: run `./install.sh` → pick Copilot → enter invalid directory → verify re-prompt
- [ ] Test: run `copilot/install.sh --target /some/dir` → verify flag still works (no regression)

## API Changes

None

## Data Model Changes

None

## Infrastructure Changes

None

## Acceptance Criteria

- [ ] Running `./install.sh` and selecting Copilot interactively prompts for the project directory
- [ ] Entering an invalid/nonexistent path re-prompts the user (does not error out)
- [ ] `--target <dir>` flag continues to work as before (backwards compatible)
- [ ] Help text (`-h`) reflects that `--target` is optional

## Open Questions

- Should the prompt offer tab-completion or a default path (e.g., current working directory)? Bash `read` doesn't support tab-completion natively — probably fine to keep it simple with a plain prompt.
