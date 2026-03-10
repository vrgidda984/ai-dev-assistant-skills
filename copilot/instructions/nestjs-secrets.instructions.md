---
applyTo: ".env*,**/config/**,**/secrets/**"
---

# Secrets Management

## Golden Rules

1. NEVER commit secrets
2. .env.local for local (gitignored)
3. SSM Parameter Store for production
4. .env.example has structure only — no real values

## File Structure

```
project/
├── .env.example      # Committed, no secrets
├── .env.local        # Gitignored, local secrets
└── src/config/
    ├── configuration.ts
    └── validation.schema.ts
```

## SSM Naming

```
/{app-name}/{env}/{VAR_NAME}
/myapp/prod/DB_PASSWORD
```

## ECS Integration

ECS task definition references SSM parameters. Secrets injected as env vars at container start. No SDK calls needed.
