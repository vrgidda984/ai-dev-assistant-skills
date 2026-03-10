# Environment Variables

_Last updated: [YYYY-MM-DD]_

## Overview

- **Local development**: `.env.local` (gitignored)
- **Production**: [e.g., AWS SSM Parameter Store, Vault, etc.]
- **Template**: `.env.example` (committed, no real values)

## Variables

| Variable | Required | Default | Description |
| -------- | -------- | ------- | ----------- |
| `NODE_ENV` | Yes | `development` | Runtime environment |
| `PORT` | No | `3000` | Application port |
| `DATABASE_URL` | Yes | — | Database connection string |

## Adding New Variables

1. Add to `.env.example` with a placeholder value
2. Add to this document
3. Add to validation schema (if applicable)
4. Update deployment configuration
