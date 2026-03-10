# Python FastAPI Backend Development Skill

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
│   ├── env.py
│   ├── script.py.mako
│   └── versions/
├── src/
│   └── my_project/
│       ├── __init__.py
│       ├── main.py                  # FastAPI app factory
│       ├── config.py                # Settings via pydantic-settings
│       ├── database.py              # SQLAlchemy engine + session
│       ├── dependencies.py          # Shared FastAPI dependencies
│       ├── models/                  # SQLAlchemy ORM models
│       │   ├── __init__.py
│       │   ├── base.py              # DeclarativeBase + mixins
│       │   └── user.py
│       ├── schemas/                 # Pydantic v2 request/response schemas
│       │   ├── __init__.py
│       │   └── user.py
│       ├── routers/                 # FastAPI routers (controllers)
│       │   ├── __init__.py
│       │   └── users.py
│       ├── services/                # Business logic
│       │   ├── __init__.py
│       │   └── user_service.py
│       ├── middleware/               # ASGI / Starlette middleware
│       │   ├── __init__.py
│       │   └── request_logging.py
│       ├── exceptions/               # Custom exception classes + handlers
│       │   ├── __init__.py
│       │   └── handlers.py
│       └── utils/                    # Shared helpers
│           ├── __init__.py
│           └── logging.py
└── tests/
    ├── __init__.py
    ├── conftest.py                   # Shared fixtures (TestClient, DB session)
    ├── unit/
    │   ├── __init__.py
    │   └── services/
    │       ├── __init__.py
    │       └── test_user_service.py
    ├── integration/
    │   ├── __init__.py
    │   └── test_user_repository.py
    └── e2e/
        ├── __init__.py
        └── test_users_api.py
```

## Naming Conventions

### Casing Quick Reference

| What | Casing | Example |
|------|--------|---------|
| File names | snake_case | `user_service.py` |
| Directories (domain) | snake_case, plural | `models/`, `routers/` |
| Packages (importable) | snake_case | `my_project` |
| Classes | PascalCase + suffix | `UserService`, `CreateUserRequest` |
| Pydantic schemas | PascalCase + purpose | `UserResponse`, `CreateUserRequest` |
| SQLAlchemy models | PascalCase, singular | `User`, `OrderItem` |
| Functions / methods | snake_case | `find_by_email()` |
| Variables / properties | snake_case | `first_name` |
| Booleans | snake_case with prefix | `is_active`, `has_role`, `can_delete` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRY_ATTEMPTS` |
| Environment vars | UPPER_SNAKE_CASE | `DATABASE_URL` |
| Route paths | kebab-case, plural nouns | `/user-profiles` |
| DB table names | snake_case, plural | `users`, `order_items` |
| DB column names | snake_case | `first_name` |
| Enum classes | PascalCase | `UserRole` |
| Enum members | UPPER_SNAKE_CASE | `ADMIN = "admin"` |
| Test files | `test_*.py` | `test_user_service.py` |
| Test classes | `TestClassName` | `TestUserService` |
| Fixtures | snake_case | `db_session`, `test_client` |

### File Naming

Pattern: `<name>.py` or `<name>_<type>.py` -- snake_case throughout.

| Type | Pattern | Example |
|------|---------|---------|
| Router | `<plural_noun>.py` | `users.py` |
| Service | `<name>_service.py` | `user_service.py` |
| Model | `<singular_noun>.py` | `user.py`, `order_item.py` |
| Schema | `<name>.py` | `user.py` (in `schemas/`) |
| Middleware | `<name>.py` | `request_logging.py` |
| Dependency | `dependencies.py` | `dependencies.py` |
| Config | `config.py` | `config.py` |
| Exception | `handlers.py` | `handlers.py` |
| Utility | `<name>.py` | `logging.py`, `pagination.py` |

### Class Naming

PascalCase with a descriptive suffix. Services use singular entity names. Models are singular. Schemas describe purpose.

| Type | Convention | Example |
|------|-----------|---------|
| Router | module-level functions | `async def create_user(...)` |
| Service | `<Entity>Service` | `UserService`, `OrderService` |
| Model | `<Singular>` | `User`, `ProductCategory` |
| Schema (create) | `Create<Entity>Request` | `CreateUserRequest` |
| Schema (update) | `Update<Entity>Request` | `UpdateUserRequest` |
| Schema (response) | `<Entity>Response` | `UserResponse` |
| Schema (list) | `<Entity>ListResponse` | `UserListResponse` |
| Exception | `<Name>Error` | `ResourceNotFoundError` |
| Dependency | function returning value | `get_db_session()`, `get_current_user()` |

### Method / Function Naming

snake_case. Do not duplicate class context -- in `UserService`, use `find_one()` not `find_one_user()`.

**Standard CRUD methods**:

| HTTP | Route | Router function | Service method |
|------|-------|----------------|----------------|
| POST / | Create | `create_user()` | `create()` |
| GET / | List | `list_users()` | `find_all()` |
| GET /{id} | Read | `get_user()` | `find_one()` |
| PATCH /{id} | Update | `update_user()` | `update()` |
| DELETE /{id} | Remove | `delete_user()` | `remove()` |

**Extended patterns**: `find_by_email()`, `find_one_or_raise()`, `create_many()`, `count_all()`

### Route Paths

- Plural nouns, kebab-case, lowercase: `/users`, `/product-categories`
- No verbs in paths -- the HTTP method conveys the action
- Nested resources for relationships: `/users/{user_id}/orders`
- Router prefix: `router = APIRouter(prefix="/users", tags=["Users"])`

### Constants and Enums

```python
# constants -- UPPER_SNAKE_CASE
MAX_RETRY_ATTEMPTS: int = 3
DEFAULT_PAGE_SIZE: int = 20

# enums -- PascalCase class, UPPER_SNAKE_CASE members, lowercase values
from enum import StrEnum

class UserRole(StrEnum):
    ADMIN = "admin"
    MODERATOR = "moderator"
    USER = "user"
```

### Test Structure

```python
class TestUserService:
    """Tests for UserService."""

    class TestCreate:
        """Tests for UserService.create."""

        def test_creates_user_successfully(self, ...) -> None: ...
        def test_raises_conflict_when_email_exists(self, ...) -> None: ...

    class TestFindOne:
        """Tests for UserService.find_one."""

        def test_returns_user_when_found(self, ...) -> None: ...
        def test_raises_not_found_when_missing(self, ...) -> None: ...
```

Test files live in `tests/` (separate from source). Test names describe the scenario: `test_<expected_behavior>_when_<condition>`.

## Code Standards

### Routers (Controllers)

- Use `APIRouter` with `prefix`, `tags`, and `responses`
- Declare `response_model` on every endpoint
- Use `Depends()` for services, auth, and DB sessions
- Thin routers -- delegate all business logic to services
- Use `status_code` parameter for non-200 responses

```python
from fastapi import APIRouter, Depends, HTTPException, status
from my_project.schemas.user import CreateUserRequest, UserResponse
from my_project.services.user_service import UserService
from my_project.dependencies import get_user_service

router = APIRouter(prefix="/users", tags=["Users"])


@router.post(
    "/",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new user",
    responses={409: {"description": "Email already exists"}},
)
async def create_user(
    body: CreateUserRequest,
    service: UserService = Depends(get_user_service),
) -> UserResponse:
    """Create a new user account."""
    return await service.create(body)


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: uuid.UUID,
    service: UserService = Depends(get_user_service),
) -> UserResponse:
    """Retrieve a user by ID."""
    return await service.find_one(user_id)
```

### Services

- Accept and return Pydantic schemas or domain types, not raw dicts
- Raise `HTTPException` or custom exceptions with appropriate status codes
- Receive dependencies via `__init__` (injected through `Depends`)
- Use structured logging (see Logging section)

```python
import uuid
import structlog
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from my_project.models.user import User
from my_project.schemas.user import CreateUserRequest, UserResponse

logger = structlog.get_logger(__name__)


class UserService:
    def __init__(self, db: Session) -> None:
        self.db = db

    def create(self, data: CreateUserRequest) -> UserResponse:
        existing = self.db.query(User).filter(User.email == data.email).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"User with email {data.email} already exists",
            )

        user = User(**data.model_dump())
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)

        logger.info(
            "User created",
            action="create_user",
            user_id=str(user.id),
            email=user.email,
        )
        return UserResponse.model_validate(user)

    def find_one(self, user_id: uuid.UUID) -> UserResponse:
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User {user_id} not found",
            )
        return UserResponse.model_validate(user)

    def find_all(self, *, skip: int = 0, limit: int = 20) -> list[UserResponse]:
        users = self.db.query(User).offset(skip).limit(limit).all()
        return [UserResponse.model_validate(u) for u in users]

    def update(self, user_id: uuid.UUID, data: UpdateUserRequest) -> UserResponse:
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User {user_id} not found",
            )
        for field, value in data.model_dump(exclude_unset=True).items():
            setattr(user, field, value)
        self.db.commit()
        self.db.refresh(user)
        return UserResponse.model_validate(user)

    def remove(self, user_id: uuid.UUID) -> None:
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User {user_id} not found",
            )
        self.db.delete(user)
        self.db.commit()
        logger.info("User deleted", action="delete_user", user_id=str(user_id))
```

### Schemas (Pydantic v2)

- Use `model_config = ConfigDict(from_attributes=True)` for ORM compatibility
- Separate request and response schemas -- never expose internal fields in requests
- Use `Field()` for validation, descriptions, and examples
- Use `model_dump(exclude_unset=True)` for partial updates

```python
import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict, EmailStr, Field


class CreateUserRequest(BaseModel):
    email: EmailStr
    name: str = Field(..., min_length=1, max_length=255, examples=["Jane Doe"])
    role: UserRole = UserRole.USER


class UpdateUserRequest(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=255)
    role: UserRole | None = None


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: EmailStr
    name: str
    role: UserRole
    is_active: bool
    created_at: datetime
    updated_at: datetime
```

### Models (SQLAlchemy 2.0)

- Use `DeclarativeBase` with `Mapped` and `mapped_column` (typed style)
- UUID primary keys
- Index frequently queried columns
- Soft deletes with `deleted_at` column
- Use mixins for common fields (timestamps, soft delete)

```python
import uuid
from datetime import datetime
from sqlalchemy import String, Boolean, Index
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy.sql import func


class Base(DeclarativeBase):
    pass


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )


class SoftDeleteMixin:
    deleted_at: Mapped[datetime | None] = mapped_column(default=None)

    @property
    def is_deleted(self) -> bool:
        return self.deleted_at is not None


class User(TimestampMixin, SoftDeleteMixin, Base):
    __tablename__ = "users"
    __table_args__ = (
        Index("ix_users_email", "email", unique=True),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True,
        default=uuid.uuid4,
    )
    email: Mapped[str] = mapped_column(String(255), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[str] = mapped_column(String(50), default="user")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
```

### Middleware

- Use Starlette `BaseHTTPMiddleware` or pure ASGI middleware
- Register in `main.py` app factory
- Common use cases: request ID injection, logging, CORS, timing

```python
import time
import uuid
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
import structlog

logger = structlog.get_logger(__name__)


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        request_id = request.headers.get("x-request-id", str(uuid.uuid4()))
        structlog.contextvars.bind_contextvars(request_id=request_id)

        start = time.perf_counter()
        response = await call_next(request)
        duration_ms = (time.perf_counter() - start) * 1000

        logger.info(
            "Request completed",
            method=request.method,
            path=request.url.path,
            status_code=response.status_code,
            duration_ms=round(duration_ms, 2),
        )

        response.headers["x-request-id"] = request_id
        structlog.contextvars.unbind_contextvars("request_id")
        return response
```

### Dependencies (FastAPI DI)

```python
from collections.abc import Generator
from fastapi import Depends
from sqlalchemy.orm import Session
from my_project.database import SessionLocal
from my_project.services.user_service import UserService


def get_db_session() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_user_service(
    db: Session = Depends(get_db_session),
) -> UserService:
    return UserService(db=db)
```

### Database (SQLAlchemy + Alembic)

**Engine and Session Setup** (`database.py`):

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from my_project.config import settings

engine = create_engine(
    settings.database_url,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,
    echo=settings.debug,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
```

**Async Alternative** (when using async endpoints with async DB):

```python
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

async_engine = create_async_engine(
    settings.async_database_url,  # postgresql+asyncpg://...
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,
)

AsyncSessionLocal = async_sessionmaker(async_engine, class_=AsyncSession, expire_on_commit=False)


async def get_async_db_session() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session
```

**Alembic Setup**:

```bash
# Initialize (run once)
uv run alembic init alembic

# Generate migration from model changes
uv run alembic revision --autogenerate -m "add users table"

# Apply migrations
uv run alembic upgrade head

# Rollback one step
uv run alembic downgrade -1
```

**Alembic env.py** (key configuration):

```python
# alembic/env.py
from my_project.models.base import Base
from my_project.config import settings

config = context.config
config.set_main_option("sqlalchemy.url", settings.database_url)
target_metadata = Base.metadata
```

**Transactions for multi-model operations**:

```python
def transfer_funds(self, from_id: uuid.UUID, to_id: uuid.UUID, amount: Decimal) -> None:
    try:
        from_account = self.db.query(Account).filter(Account.id == from_id).with_for_update().one()
        to_account = self.db.query(Account).filter(Account.id == to_id).with_for_update().one()

        from_account.balance -= amount
        to_account.balance += amount

        self.db.commit()
    except Exception:
        self.db.rollback()
        raise
```

### Logging

**Structured Logging with structlog**:

Configure once in `main.py` or a `logging.py` utility:

```python
import structlog
import logging


def setup_logging(*, json_output: bool = True, log_level: str = "INFO") -> None:
    """Configure structlog for structured JSON logging."""
    shared_processors: list[structlog.types.Processor] = [
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_log_level,
        structlog.stdlib.add_logger_name,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.UnicodeDecoder(),
    ]

    if json_output:
        renderer = structlog.processors.JSONRenderer()
    else:
        renderer = structlog.dev.ConsoleRenderer()

    structlog.configure(
        processors=[
            *shared_processors,
            structlog.stdlib.ProcessorFormatter.wrap_for_formatter,
        ],
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )

    formatter = structlog.stdlib.ProcessorFormatter(
        processors=[
            structlog.stdlib.ProcessorFormatter.remove_processors_meta,
            renderer,
        ],
        foreign_pre_chain=shared_processors,
    )

    handler = logging.StreamHandler()
    handler.setFormatter(formatter)

    root_logger = logging.getLogger()
    root_logger.addHandler(handler)
    root_logger.setLevel(log_level)
```

**Standard Log Context** (consistent across all services):

```python
# Required fields
logger.info(
    "Operation description",
    action="create_user",           # Operation identifier
    service="UserService",          # Service/class name
)

# Full context for critical operations
logger.info(
    "User created",
    action="create_user",
    service="UserService",
    user_id="abc-123",              # User performing action
    resource_id="def-456",          # Resource being acted upon
    request_id="req-789",           # Correlation ID (from contextvars)
    duration_ms=42.5,               # Operation timing
)

# Error logging (always include exc_info or exception details)
logger.error(
    "Failed to create user",
    action="create_user",
    service="UserService",
    error_code="DUPLICATE_EMAIL",
    exc_info=True,                  # Includes traceback
)
```

**Log Levels**:
- `debug`: Development/debugging (verbose payloads, SQL queries)
- `info`: Normal operations (key identifiers, durations)
- `warning`: Recoverable issues (retries, deprecation usage)
- `error`: Failures (always include exception info)
- `critical`: System-level failures (DB down, config missing)

**Sensitive Data Sanitization**:

CRITICAL: Never log sensitive information. Always sanitize before logging.

**Always Exclude from Logs**:
- `password`, `password_hash`, `current_password`, `new_password`
- `token`, `access_token`, `refresh_token`, `api_key`, `secret`
- `credit_card`, `cvv`, `card_number`, `ssn`, `tax_id`
- `private_key`, `secret_key`, `encryption_key`
- Full request/response bodies without filtering

**Sanitization Helper**:

```python
SENSITIVE_KEYS = frozenset({
    "password", "password_hash", "token", "access_token",
    "refresh_token", "api_key", "secret", "credit_card",
    "cvv", "card_number", "ssn", "private_key", "secret_key",
})


def sanitize_for_log(data: dict[str, object], *, extra_keys: frozenset[str] | None = None) -> dict[str, object]:
    """Remove sensitive keys from a dict before logging."""
    keys_to_remove = SENSITIVE_KEYS | (extra_keys or frozenset())
    return {k: v for k, v in data.items() if k not in keys_to_remove}


# Usage
logger.info(
    "User login attempt",
    action="login",
    payload=sanitize_for_log(login_data.model_dump()),
)
```

**Required Sanitization Checklist**:
- [ ] Remove passwords from authentication payloads
- [ ] Remove tokens from authorization headers
- [ ] Mask credit card numbers (show last 4 only if needed)
- [ ] Exclude API keys and secrets
- [ ] Filter PII based on compliance requirements (GDPR, HIPAA)
- [ ] Sanitize error messages that may contain sensitive query parameters

### Configuration (pydantic-settings)

```python
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env.local",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Application
    app_name: str = "my-project"
    debug: bool = False
    log_level: str = "INFO"
    environment: str = "local"

    # Database
    database_url: str
    async_database_url: str = ""

    # Auth
    jwt_secret: str = ""
    jwt_algorithm: str = "HS256"
    jwt_expiration_minutes: int = 30


settings = Settings()
```

### App Factory (`main.py`)

```python
from contextlib import asynccontextmanager
from collections.abc import AsyncIterator
from fastapi import FastAPI
from my_project.config import settings
from my_project.utils.logging import setup_logging
from my_project.routers import users
from my_project.middleware.request_logging import RequestLoggingMiddleware
from my_project.exceptions.handlers import register_exception_handlers


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    setup_logging(json_output=settings.environment != "local", log_level=settings.log_level)
    yield


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        debug=settings.debug,
        lifespan=lifespan,
    )

    # Middleware (order matters: last added = first executed)
    app.add_middleware(RequestLoggingMiddleware)

    # Exception handlers
    register_exception_handlers(app)

    # Routers
    app.include_router(users.router)

    return app


app = create_app()
```

### pyproject.toml Reference

```toml
[project]
name = "my-project"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.115",
    "uvicorn[standard]>=0.30",
    "sqlalchemy>=2.0",
    "alembic>=1.14",
    "pydantic[email]>=2.0",
    "pydantic-settings>=2.0",
    "structlog>=24.0",
    "psycopg2-binary>=2.9",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-cov>=5.0",
    "pytest-asyncio>=0.24",
    "httpx>=0.27",
    "mypy>=1.11",
    "ruff>=0.6",
    "factory-boy>=3.3",
]

[tool.ruff]
target-version = "py312"
line-length = 120
src = ["src"]

[tool.ruff.lint]
select = ["E", "F", "W", "I", "N", "UP", "B", "A", "C4", "SIM", "TCH", "RUF"]

[tool.ruff.lint.isort]
known-first-party = ["my_project"]

[tool.mypy]
strict = true
plugins = ["pydantic.mypy"]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = "--strict-markers -ra"
markers = [
    "integration: marks tests as integration tests (deselect with '-m \"not integration\"')",
    "e2e: marks tests as end-to-end tests (deselect with '-m \"not e2e\"')",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["src/my_project"]
```
