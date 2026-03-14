# AI Dev Assistant Skills

A curated collection of reusable workflows, agents, stack conventions, and documentation templates for AI-assisted development — supporting both **Claude Code** and **GitHub Copilot** from a single source of truth.

### What's in the box

- **Workflows** — session handoff, feature planning, code review, doc updates, commit/PR automation
- **Agents** — architect, code reviewer, docs writer
- **Stack packs** — framework-specific conventions (NestJS, Python/FastAPI) for coding standards, testing, and secrets management
- **Docs scaffold** — ready-made documentation structure for new projects

### How the installer works

`install.sh` is a root dispatcher. It asks which AI tool you use, then delegates to the tool-specific installer. Use `--tool claude` or `--tool copilot` to skip the prompt. All other flags are passed through to the sub-installer.

### Which tool should I choose?

| | Claude Code | GitHub Copilot |
|---|---|---|
| **Use if** | You use the Claude Code CLI | You use Copilot Chat in VS Code / JetBrains |
| **Installs to** | `~/.claude/` (global — available across all projects) | `.github/` in your project (per-project) |
| **Format** | Skills, commands, agents, stacks | Prompts, agents, instructions |

You can install both if you use both tools — they don't conflict.

## Quick Start

### Claude Code

```bash
./install.sh --tool claude
# Or directly: ./claude/install.sh
```

Installs globally to `~/.claude/` (skills, agents, commands, stack packs).

### GitHub Copilot

```bash
./install.sh --tool copilot --target /path/to/your/project
# Or directly: ./copilot/install.sh --target /path/to/your/project
```

Installs per-project into `.github/` (prompts, agents, instructions).

## What's Included

### Workflows

| Workflow | Claude | Copilot |
|----------|--------|---------|
| Session handoff | `skills/session-handoff/` + `commands/handoff.md` | `prompts/session-handoff.prompt.md` |
| Resume session | _(N/A — persistent memory)_ | `prompts/resume-session.prompt.md` |
| Plan feature | `skills/plan-feature/` + `commands/plan.md` | `prompts/plan-feature.prompt.md` |
| Code review | `skills/code-review/` + `commands/review.md` | `prompts/code-review.prompt.md` |
| Update docs | `skills/update-docs/` + `commands/update-docs.md` | `prompts/update-docs.prompt.md` |
| Sync README | `skills/readme-updater/` + `commands/sync-readme.md` | `prompts/sync-readme.prompt.md` |
| Repo init | `skills/repo-init/` + `commands/init.md` | `prompts/repo-init.prompt.md` |
| Commit & push | `skills/github-commit-push/` + `commands/github-commit-push.md` | `prompts/commit-push.prompt.md` |
| Create PR | `skills/github-create-pr/` + `commands/github-create-pr.md` | `prompts/create-pr.prompt.md` |

### Agents

| Agent | Claude | Copilot |
|-------|--------|---------|
| Architect | `agents/architect.md` | `agents/architect.agent.md` |
| Code reviewer | `agents/code-reviewer.md` | `agents/code-reviewer.agent.md` |
| Docs writer | `agents/docs-writer.md` | `agents/docs-writer.agent.md` |

### Stack Packs

| Stack | Claude | Copilot |
|-------|--------|---------|
| NestJS | `stacks/nestjs/` (SKILL.md, testing.md, secrets.md) | `instructions/nestjs*.instructions.md` (3 files) |
| Python/FastAPI | `stacks/python/` (SKILL.md, testing.md, secrets.md) | `instructions/python*.instructions.md` (3 files) |

### Shared

- **`docs-scaffold/`** — Template documentation structure for new projects (used by both tools' repo-init)

## Concept Mapping

| Concept | Claude Code | GitHub Copilot |
|---------|-------------|----------------|
| Global config | `~/.claude/` (global install) | `.github/copilot-instructions.md` (per-project) |
| Slash commands | `commands/*.md` | `prompts/*.prompt.md` |
| Workflow logic | `skills/*/SKILL.md` | _(embedded in prompt files)_ |
| Agents | `agents/*.md` | `agents/*.agent.md` (with `tools` frontmatter) |
| Stack conventions | `stacks/<name>/SKILL.md` | `instructions/<name>.instructions.md` (with `applyTo` frontmatter) |

## Adding a New Workflow

When adding a new workflow, create the equivalent in **both** directories:

1. **Claude**: add skill in `claude/skills/<name>/SKILL.md` + command in `claude/commands/<name>.md`
2. **Copilot**: add prompt in `copilot/prompts/<name>.prompt.md`
3. Run `./scripts/drift-check.sh` to verify coverage

## Adding a New Stack Pack

1. **Claude**: create `claude/stacks/<name>/SKILL.md` (+ `testing.md`, `secrets.md`)
2. **Copilot**: create `copilot/instructions/<name>.instructions.md` (+ `-testing`, `-secrets` variants with `applyTo` frontmatter)
3. Run `./scripts/drift-check.sh`

## Keeping Content in Sync

The `scripts/drift-check.sh` script checks that:
- Every agent exists in both `claude/` and `copilot/`
- Every workflow has its equivalent in both directories
- Every stack pack has corresponding files in both
- Files haven't drifted apart (warns if one side was updated 7+ days after the other)

```bash
./scripts/drift-check.sh
```

## Repo Structure

```
ai-dev-assistant-skills/
├── claude/              # Claude Code payload (self-contained)
│   ├── agents/
│   ├── commands/
│   ├── skills/
│   ├── stacks/
│   ├── install.sh
│   └── uninstall.sh
├── copilot/             # GitHub Copilot payload (self-contained)
│   ├── agents/
│   ├── prompts/
│   ├── instructions/
│   ├── copilot-instructions.md
│   ├── install.sh
│   └── uninstall.sh
├── docs-scaffold/       # Shared project templates
├── scripts/
│   └── drift-check.sh
├── install.sh           # Root dispatcher
└── uninstall.sh         # Root dispatcher
```

## Uninstalling

```bash
# Claude
./uninstall.sh --tool claude

# Copilot
./uninstall.sh --tool copilot --target /path/to/your/project
```

Only removes files matching names from this repo (with confirmation prompts).
