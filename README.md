# AI Dev Assistant Skills

A curated collection of reusable workflows, agents, stack conventions, and documentation templates for AI-assisted development — supporting both **Claude Code** and **GitHub Copilot** from a single source of truth.

### What's in the box

- **Workflows** — session handoff, feature planning, code review, doc updates, commit/PR automation, repo initialization
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
| **Format** | Skills, agents, stacks | Prompts, agents, instructions |

You can install both if you use both tools — they don't conflict.

## Quick Start

### Claude Code

```bash
./install.sh --tool claude
# Or directly: ./claude/install.sh
```

Installs globally to `~/.claude/` (skills, agents, stack packs).

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
| Session handoff | `skills/session-handoff/` | `prompts/session-handoff.prompt.md` |
| Resume session | _(N/A — persistent memory)_ | `prompts/resume-session.prompt.md` |
| Plan feature | `skills/plan-feature/` | `prompts/plan-feature.prompt.md` |
| Code review | `skills/code-review/` | `prompts/code-review.prompt.md` |
| Update docs | `skills/update-docs/` | `prompts/update-docs.prompt.md` |
| Sync README | `skills/readme-updater/` | `prompts/sync-readme.prompt.md` |
| Repo init | `skills/repo-init/` | `prompts/repo-init.prompt.md` |
| Commit & push | `skills/github-commit-push/` | `prompts/commit-push.prompt.md` |
| Create PR | `skills/github-create-pr/` | `prompts/create-pr.prompt.md` |

#### Workflow Details

**Session handoff** — Saves your current working context so you can pick up where you left off in a new session. Useful when the tool closes, context gets too long, or you want to start a fresh thread. Overwrites `docs/sessions/current-state.md` with system overview, current status, and next steps. Appends a dated entry to `docs/sessions/changelog.md`.

> **Note:** `docs/sessions/` is local working state — add it to your project's `.gitignore`.

**Resume session** — _(Copilot only)_ Reads `current-state.md` and the changelog to restore context when starting a new session. Claude Code handles this natively via persistent memory.

**Plan feature** — Guides structured feature planning before writing any code. Discusses requirements with the user, reads existing architecture docs, and produces a plan file at `docs/plans/active/[feature-name].md` covering goals, approach, tasks, API/data model changes, and acceptance criteria.

**Code review** — Performs a structured review against a comprehensive checklist: framework patterns, TypeScript/language strictness, API design, infrastructure, testing, security, and documentation. Groups findings by severity — Critical, Warning, and Suggestion — and explains *why* each issue matters.

**Update docs** — Scans recent code changes (via git diff or conversation context) and surgically updates the relevant documentation files: architecture overview, API contracts, data model, infrastructure, environment variables, and setup guides. Appends a changelog entry and checks if the README needs syncing.

**Sync README** — Compares `README.md` against `docs/` files (`current-state.md`, `overview.md`, `local-development.md`, `environment-variables.md`) and updates sections to match current project state. Keeps the README concise as an entry point, linking to `docs/` for details.

**Repo init** — Analyzes an existing repository and generates a complete `docs/` structure populated with real project data. This is the most comprehensive workflow — see [Repo Init Details](#repo-init-details) below.

**Commit & push** — Analyzes uncommitted changes, groups them logically by concern (feature, fix, test, docs, chore, refactor, style), and creates separate Conventional Commits for each group. Requires explicit user confirmation before every git operation.

**Create PR** — Creates a draft GitHub pull request using the repo's PR template (if one exists). Auto-populates the PR body from the diff and commit log. Requires the `gh` CLI to be installed and authenticated, and asks for user confirmation before creating.

### Repo Init Details

The `repo-init` workflow is a 5-phase process that bootstraps a project's documentation from its actual codebase:

**Phase 1 — Discover.** Reads all existing documentation (README, CONTRIBUTING, docs/), manifest files (package.json, pyproject.toml, etc.), Docker configs, schema files (Prisma, GraphQL), and API specs (OpenAPI, Swagger). Catalogs existing documentation depth. Detects the tech stack: language, framework, database, ORM, infrastructure, test framework, and linter.

**Phase 1.5 — Stack Selection.** Auto-detects which stack packs apply based on project files:
- **NestJS** — `@nestjs/core` in package.json
- **Python/FastAPI** — `fastapi` in pyproject.toml
- **Next.js** — `next` in package.json
- **React** — `react` in package.json (without `next`)
- **Terraform** — `*.tf` files present

Presents detection results and asks for confirmation before proceeding.

**Phase 2 — Deep Code Analysis.** Goes beyond config files to scan actual source code using stack-specific patterns. Builds inventories of:
- **API endpoints** — method, path, handler function, file:line (e.g., `@Get`, `@Post` for NestJS; `@router.get` for FastAPI)
- **Data models** — entity name, fields with types, relationships (e.g., Prisma `model`, TypeORM `@Entity`, SQLAlchemy `Base`)
- **Environment variables** — variable name, where used, defaults (e.g., `process.env.`, `os.getenv`)
- **Test coverage** — test file locations, CI/CD pipeline configs

**Phase 2.5 — Validation Report.** Compares code analysis inventories against existing documentation and presents a discrepancy matrix:
- **MATCH** — code and docs agree
- **MISMATCH** — both mention it but details differ
- **UNDOCUMENTED** — exists in code but not in docs
- **STALE** — mentioned in docs but not found in code

Requires explicit user approval (or corrections) before proceeding to scaffold.

**Phase 3 — Scaffold.** Moves pre-existing docs to `old_docs_not_relevant/` (with `OLD_` prefix) for reference, preserving nothing is lost. Creates 11 documentation files:

| File | Content |
|------|---------|
| `docs/architecture/overview.md` | System overview, tech stack, module map, data flow |
| `docs/architecture/api-contracts.md` | All endpoints with request/response shapes |
| `docs/architecture/data-model.md` | Entities, fields, relationships, migrations |
| `docs/architecture/infrastructure.md` | Hosting, Docker services, deployment |
| `docs/setup/local-development.md` | Prerequisites, quick start, running tests |
| `docs/setup/environment-variables.md` | All env vars with descriptions and defaults |
| `docs/setup/deployment.md` | Environments, deploy process, rollback |
| `docs/decisions/_template.md` | ADR template for architecture decisions |
| `docs/sessions/current-state.md` | Current system state and next steps |
| `docs/sessions/changelog.md` | Change history (newest first) |
| `docs/plans/active/`, `completed/` | Feature plan directories |

**Phase 4 — CLAUDE.md.** Creates or updates the project's `CLAUDE.md` with detected stack, development commands, project structure, and references to installed stack skills.

**Phase 5 — Summary.** Prints what was created, stacks applied, discrepancies resolved, and remaining `<!-- TODO -->` items to fill in manually.

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
| Workflow logic | `skills/*/SKILL.md` | `prompts/*.prompt.md` |
| Agents | `agents/*.md` | `agents/*.agent.md` (with `tools` frontmatter) |
| Stack conventions | `stacks/<name>/SKILL.md` | `instructions/<name>.instructions.md` (with `applyTo` frontmatter) |

## Adding a New Workflow

When adding a new workflow, create the equivalent in **both** directories:

1. **Claude**: add skill in `claude/skills/<name>/SKILL.md`
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
