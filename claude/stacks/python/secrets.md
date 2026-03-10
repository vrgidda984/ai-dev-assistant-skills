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

### .env.example

```env
# Application
APP_NAME=my-project
DEBUG=false
LOG_LEVEL=INFO
ENVIRONMENT=local

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# Auth
JWT_SECRET=
JWT_ALGORITHM=HS256
JWT_EXPIRATION_MINUTES=30
```

### .gitignore (secrets-related entries)

```gitignore
# Environment files
.env
.env.local
.env.*.local

# Secrets
*.pem
*.key
credentials.json
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
    log_level: str = "INFO"
    environment: str = "local"

    database_url: str  # Required -- no default, fails fast if missing
    jwt_secret: str = ""
    jwt_algorithm: str = "HS256"
    jwt_expiration_minutes: int = 30


settings = Settings()
```

Pydantic-settings automatically reads from environment variables (highest priority) and then falls back to the `.env.local` file. In production, environment variables are injected by the container runtime -- no `.env` file needed.

## SSM Naming

```
/{app-name}/{env}/{VAR_NAME}
/myapp/prod/DATABASE_URL
/myapp/prod/JWT_SECRET
/myapp/staging/DATABASE_URL
```

## ECS Integration

ECS task definition references SSM parameters. Secrets are injected as environment variables at container start. No AWS SDK calls needed in application code.

```json
{
  "containerDefinitions": [
    {
      "name": "my-project",
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:ssm:us-east-1:123456789:parameter/myapp/prod/DATABASE_URL"
        },
        {
          "name": "JWT_SECRET",
          "valueFrom": "arn:aws:ssm:us-east-1:123456789:parameter/myapp/prod/JWT_SECRET"
        }
      ]
    }
  ]
}
```

## Lambda Integration

For Lambda deployments, use SSM Parameter Store or Secrets Manager referenced in the function configuration:

```yaml
# serverless.yml / SAM template
Environment:
  Variables:
    DATABASE_URL: !Sub "{{resolve:ssm:/myapp/${Stage}/DATABASE_URL}}"
    JWT_SECRET: !Sub "{{resolve:ssm:/myapp/${Stage}/JWT_SECRET}}"
```

## Validation at Startup

Pydantic-settings validates all required fields at import time. If `DATABASE_URL` is missing, the app fails immediately with a clear error rather than crashing later at first database access.

```
pydantic_settings.SettingsError: 1 validation error for Settings
database_url
  Field required [type=missing, input_value={}, input_type=dict]
```
