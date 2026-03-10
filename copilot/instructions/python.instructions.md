---
applyTo: "**/*.py"
---

# Python FastAPI Backend Development

## Core Principles

- **Type Safety**: mypy strict mode, full type annotations everywhere
- **Standard Layout**: `src/` layout with `pyproject.toml` (PEP 621)
- **Dependency Injection**: FastAPI `Depends()` for all shared resources
- **Fail Fast**: Validate early with Pydantic v2, raise HTTPException with clear codes
- **Documentation**: OpenAPI auto-generated, augmented with docstrings and `response_model`
- **ORM**: SQLAlchemy 2.0 with Alembic migrations
- **Tooling**: ruff for linting/formatting, mypy for type checking, pytest for testing
- **Package Manager**: uv for fast, reproducible dependency management

## Project Structure

```
my-project/
├── pyproject.toml
├── uv.lock
├── alembic.ini
├── alembic/
├── src/
│   └── my_project/
│       ├── __init__.py
│       ├── main.py                  # FastAPI app factory
│       ├── config.py                # Settings via pydantic-settings
│       ├── database.py              # SQLAlchemy engine + session
│       ├── dependencies.py          # Shared FastAPI dependencies
│       ├── models/                  # SQLAlchemy ORM models
│       ├── schemas/                 # Pydantic v2 request/response schemas
│       ├── routers/                 # FastAPI routers (controllers)
│       ├── services/                # Business logic
│       ├── middleware/
│       ├── exceptions/
│       └── utils/
└── tests/
    ├── conftest.py
    ├── unit/
    ├── integration/
    └── e2e/
```

## Naming Conventions

### Casing Quick Reference

| What | Casing | Example |
|------|--------|---------|
| File names | snake_case | `user_service.py` |
| Directories | snake_case | `models/`, `routers/` |
| Packages | snake_case | `my_project` |
| Classes | PascalCase + suffix | `UserService`, `CreateUserRequest` |
| Pydantic schemas | PascalCase + purpose | `UserResponse`, `CreateUserRequest` |
| SQLAlchemy models | PascalCase, singular | `User`, `OrderItem` |
| Functions / methods | snake_case | `find_by_email()` |
| Variables | snake_case | `first_name` |
| Booleans | snake_case with prefix | `is_active`, `has_role` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRY_ATTEMPTS` |
| Route paths | kebab-case, plural nouns | `/user-profiles` |
| DB table names | snake_case, plural | `users`, `order_items` |
| Enum classes | PascalCase | `UserRole` |
| Enum members | UPPER_SNAKE_CASE | `ADMIN = "admin"` |
| Test files | `test_*.py` | `test_user_service.py` |
| Test classes | `TestClassName` | `TestUserService` |

### Class Naming

| Type | Convention | Example |
|------|-----------|---------|
| Service | `<Entity>Service` | `UserService` |
| Model | `<Singular>` | `User`, `ProductCategory` |
| Schema (create) | `Create<Entity>Request` | `CreateUserRequest` |
| Schema (update) | `Update<Entity>Request` | `UpdateUserRequest` |
| Schema (response) | `<Entity>Response` | `UserResponse` |
| Exception | `<Name>Error` | `ResourceNotFoundError` |

### Standard CRUD methods

| HTTP | Route | Router function | Service method |
|------|-------|----------------|----------------|
| POST / | Create | `create_user()` | `create()` |
| GET / | List | `list_users()` | `find_all()` |
| GET /{id} | Read | `get_user()` | `find_one()` |
| PATCH /{id} | Update | `update_user()` | `update()` |
| DELETE /{id} | Remove | `delete_user()` | `remove()` |

## Code Standards

### Routers (Controllers)

- Use `APIRouter` with `prefix`, `tags`, and `responses`
- Declare `response_model` on every endpoint
- Use `Depends()` for services, auth, and DB sessions
- Thin routers — delegate all business logic to services

```python
router = APIRouter(prefix="/users", tags=["Users"])

@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    body: CreateUserRequest,
    service: UserService = Depends(get_user_service),
) -> UserResponse:
    return await service.create(body)
```

### Services

- Accept and return Pydantic schemas or domain types, not raw dicts
- Raise `HTTPException` or custom exceptions with appropriate status codes
- Receive dependencies via `__init__` (injected through `Depends`)
- Use structured logging (see Logging section)

### Schemas (Pydantic v2)

- Use `model_config = ConfigDict(from_attributes=True)` for ORM compatibility
- Separate request and response schemas
- Use `Field()` for validation, descriptions, and examples
- Use `model_dump(exclude_unset=True)` for partial updates

### Models (SQLAlchemy 2.0)

- Use `DeclarativeBase` with `Mapped` and `mapped_column` (typed style)
- UUID primary keys
- Index frequently queried columns
- Soft deletes with `deleted_at` column
- Use mixins for common fields (timestamps, soft delete)

### Dependencies (FastAPI DI)

```python
def get_db_session() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_user_service(db: Session = Depends(get_db_session)) -> UserService:
    return UserService(db=db)
```

### Database (SQLAlchemy + Alembic)

```bash
uv run alembic revision --autogenerate -m "add users table"
uv run alembic upgrade head
uv run alembic downgrade -1
```

### Logging

Use structlog for structured JSON logging.

**Standard Log Context**:

```python
logger.info(
    "User created",
    action="create_user",
    service="UserService",
    user_id="abc-123",
    resource_id="def-456",
    duration_ms=42.5,
)
```

**Sensitive Data Sanitization**:

CRITICAL: Never log sensitive information. Always sanitize before logging.

**Always Exclude from Logs**:
- `password`, `password_hash`, `current_password`, `new_password`
- `token`, `access_token`, `refresh_token`, `api_key`, `secret`
- `credit_card`, `cvv`, `card_number`, `ssn`, `tax_id`
- `private_key`, `secret_key`, `encryption_key`

```python
SENSITIVE_KEYS = frozenset({
    "password", "password_hash", "token", "access_token",
    "refresh_token", "api_key", "secret", "credit_card",
    "cvv", "card_number", "ssn", "private_key", "secret_key",
})

def sanitize_for_log(data: dict[str, object]) -> dict[str, object]:
    return {k: v for k, v in data.items() if k not in SENSITIVE_KEYS}
```

### Configuration (pydantic-settings)

```python
class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env.local", case_sensitive=False)
    app_name: str = "my-project"
    debug: bool = False
    database_url: str
    jwt_secret: str = ""
```

### pyproject.toml Reference

Use hatchling build backend, ruff for linting, mypy strict mode, pytest with markers for test tiers.
