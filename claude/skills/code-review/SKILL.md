---
name: code-review
description: >
  Review code for quality, patterns, and best practices. This skill
  should be used when the user asks to "review code", "check my code",
  "review changes", "review PR", "quality check", or before merging
  significant features. Also use when a feature is completed and needs
  a quality gate before merge.
---

# Code Review

Perform a structured code review against project standards.

## When to Use

Before merging features, after significant implementations, or on request.

## Steps

1. Identify the scope of review (specific files, a feature, or recent changes).
2. Read `docs/architecture/overview.md` for project context.
3. Read the project's `CLAUDE.md` for stack-specific conventions.
4. Review code against each checklist section below.
5. Report findings grouped by severity.

## Checklist

### Framework Patterns

- Proper separation of concerns (controllers/handlers, services, data layer)
- Input validation on all entry points (DTOs, request schemas, etc.)
- Proper dependency management (use DI where available, no manual instantiation)
- Exception/error handling uses framework conventions
- Cross-cutting concerns handled consistently (logging, auth, caching)
- Module boundaries respected (no improper cross-module imports)

### TypeScript / Language

- Strict mode compliance (no untyped `any` without justification)
- Proper interface/type definitions for all data shapes
- Null safety handled (no unsafe optional chaining assumptions)
- Enums or union types for fixed value sets
- Consistent coding style throughout

### API Design

- RESTful or consistent API conventions followed
- Consistent error response format across endpoints
- Proper HTTP status codes (201 for create, 204 for delete, etc.)
- Input validation on all endpoints
- Endpoints documented (Swagger, JSDoc, or equivalent)

### Infrastructure

- New services/components have deployment configuration
- Environment variables documented in `docs/setup/environment-variables.md`
- Infrastructure-as-code updated if applicable

### Testing

- Unit tests for services (business logic)
- Integration/controller tests for endpoint behavior
- E2E tests for critical user flows
- Edge cases covered (empty inputs, invalid data, auth failures)

### Security

- No secrets or credentials in code (use env vars)
- Input validation on all user-facing endpoints
- Auth on protected routes
- Injection prevention (SQL, NoSQL, command injection)

### Documentation

- Architecture docs reflect current changes
- API contracts updated with new/modified endpoints
- Changelog entry added for significant changes
- ADR created for architectural decisions

## Output Format

Group findings by severity:

1. **Critical** — Must fix before merge (bugs, security issues, data loss risks)
2. **Warning** — Should fix, creates tech debt if not (pattern violations, missing tests)
3. **Suggestion** — Nice to have (style improvements, minor optimizations)

For each finding, explain WHY it matters, not just WHAT to change.

## Slash Command Fallback

If this skill doesn't auto-trigger, use: `/review [scope]`
