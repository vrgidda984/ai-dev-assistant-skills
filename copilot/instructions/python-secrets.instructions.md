---
applyTo: ".env*,**/config.py,**/settings.py"
---

# Secrets Management

## Golden Rules

1. NEVER commit secrets
2. `.env.local` for local development (gitignored)
3. SSM Parameter Store for production
4. `.env.example` has structure only -- no real values

## File Structure

```
project/
├── .env.example          # Committed, no secrets -- structure only
├── .env.local            # Gitignored, local secrets
├── .gitignore            # Must include .env.local, .env, *.pem
└── src/my_project/
    └── config.py         # pydantic-settings loads from env
```

### config.py (pydantic-settings)

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env.local",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )
    app_name: str = "my-project"
    debug: bool = False
    database_url: str  # Required -- fails fast if missing
    jwt_secret: str = ""

settings = Settings()
```

## SSM Naming

```
/{app-name}/{env}/{VAR_NAME}
/myapp/prod/DATABASE_URL
/myapp/prod/JWT_SECRET
```

## ECS Integration

ECS task definition references SSM parameters. Secrets are injected as environment variables at container start. No AWS SDK calls needed in application code.

## Validation at Startup

Pydantic-settings validates all required fields at import time. If `DATABASE_URL` is missing, the app fails immediately with a clear error.
