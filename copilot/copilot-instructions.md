# Coding Standards

These rules apply to all code in this repository. Framework-specific conventions are in `.github/instructions/`.

## Core Principles

1. **TypeScript strict mode** in all TypeScript projects
2. **Type safety first** — mypy strict for Python, strictNullChecks for TypeScript
3. **Test all business logic** — 80%+ coverage target
4. **Document APIs** with Swagger/OpenAPI, JSDoc, or equivalent
5. **Framework exception handling** — use framework-specific error types, never bare throws
6. **NEVER commit secrets** — use environment-specific secret management

## Commit Conventions

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<optional scope>): <description>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `build`, `ci`, `perf`

- Keep subject line under 72 characters
- Add a body (separated by blank line) when the change warrants explanation
- Group related changes into logical commits

## Documentation Standards

Project documentation lives in `docs/` at the project root:

- `docs/architecture/` — System design, API contracts, data model, infrastructure
- `docs/decisions/` — Architecture Decision Records (ADRs)
- `docs/sessions/` — Session state snapshot and changelog
- `docs/plans/` — Feature plans (active and completed)
- `docs/setup/` — Local development, environment variables, deployment

Update relevant docs when making significant code changes.

## API Design

- RESTful conventions: plural nouns, proper HTTP verbs, no verbs in paths
- Consistent error response format across endpoints
- Proper HTTP status codes (201 for create, 204 for delete, 400 for validation, 404 for not found)
- Input validation on all endpoints
- Pagination for list endpoints

## Logging

- Use structured logging (JSON format in production)
- Required fields: `action` (operation identifier), `service` (class/module name)
- Optional: `userId`, `resourceId`, `traceId`, `duration_ms`
- **NEVER log**: passwords, tokens, API keys, credit card numbers, SSNs, private keys
- Sanitize payloads before logging — extract only relevant fields

## Security

- No secrets or credentials in code — use `.env.local` (gitignored) locally
- Production secrets via cloud-native management (SSM, Vault, etc.)
- `.env.example` committed with structure only, no real values
- Input validation on all user-facing endpoints
- Auth on all non-public endpoints
- Injection prevention (SQL, NoSQL, command injection)

## Stack-Specific Conventions

For framework-specific coding standards, see the instruction files in `.github/instructions/`:

- **NestJS**: `nestjs.instructions.md` (auto-applied to `src/**/*.ts`)
- **NestJS Testing**: `nestjs-testing.instructions.md` (auto-applied to `**/*.spec.ts`)
- **Python/FastAPI**: `python.instructions.md` (auto-applied to `**/*.py`)
- **Python Testing**: `python-testing.instructions.md` (auto-applied to `tests/**/*.py`)
