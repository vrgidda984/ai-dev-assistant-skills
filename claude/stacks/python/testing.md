# Python FastAPI Testing Standards

## Test Pyramid

- Unit: 70% (services, business logic, utilities)
- Integration: 20% (database interactions, model queries)
- E2E: 10% (API flows via TestClient, complete user journeys)

## Coverage Requirements

- Statements: 80%
- Branches: 75%
- Functions: 80%
- Lines: 80%

Run coverage: `uv run pytest --cov=src --cov-report=term-missing --cov-fail-under=80`

## Naming Convention

```python
class TestUserService:
    """Tests for UserService."""

    class TestCreate:
        """Tests for UserService.create."""

        def test_creates_user_successfully(self, ...) -> None:
            """Should create user when valid data provided."""

        def test_raises_conflict_when_email_exists(self, ...) -> None:
            """Should raise 409 when email already exists."""
```

Pattern: `test_<expected_behavior>_when_<condition>` or `test_<action>_<outcome>`.

## Test Configuration

### conftest.py (Shared Fixtures)

```python
# tests/conftest.py
import pytest
from collections.abc import Generator
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, StaticPool
from sqlalchemy.orm import sessionmaker, Session
from my_project.main import create_app
from my_project.dependencies import get_db_session
from my_project.models.base import Base

# In-memory SQLite for unit/fast tests
TEST_DATABASE_URL = "sqlite://"

engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(autouse=True)
def _setup_db() -> Generator[None, None, None]:
    """Create tables before each test and drop after."""
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def db_session() -> Generator[Session, None, None]:
    """Provide a transactional database session for tests."""
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.rollback()
        session.close()


@pytest.fixture
def test_client(db_session: Session) -> TestClient:
    """Create a FastAPI TestClient with overridden DB dependency."""
    app = create_app()

    def _override_db() -> Generator[Session, None, None]:
        yield db_session

    app.dependency_overrides[get_db_session] = _override_db
    return TestClient(app)
```

## Unit Testing Services

### Testing Services with Mocked Database

Always mock the database session in unit tests:

```python
# tests/unit/services/test_user_service.py
import uuid
from unittest.mock import MagicMock
import pytest
from fastapi import HTTPException
from my_project.services.user_service import UserService
from my_project.schemas.user import CreateUserRequest


class TestUserService:
    """Tests for UserService."""

    @pytest.fixture
    def mock_db(self) -> MagicMock:
        return MagicMock()

    @pytest.fixture
    def service(self, mock_db: MagicMock) -> UserService:
        return UserService(db=mock_db)

    class TestCreate:
        """Tests for UserService.create."""

        def test_creates_user_successfully(
            self, service: UserService, mock_db: MagicMock
        ) -> None:
            create_dto = CreateUserRequest(
                email="test@example.com", name="Test User"
            )
            mock_db.query.return_value.filter.return_value.first.return_value = None

            result = service.create(create_dto)

            mock_db.add.assert_called_once()
            mock_db.commit.assert_called_once()
            mock_db.refresh.assert_called_once()

        def test_raises_conflict_when_email_exists(
            self, service: UserService, mock_db: MagicMock
        ) -> None:
            create_dto = CreateUserRequest(
                email="test@example.com", name="Test User"
            )
            mock_db.query.return_value.filter.return_value.first.return_value = (
                MagicMock()  # existing user
            )

            with pytest.raises(HTTPException) as exc_info:
                service.create(create_dto)

            assert exc_info.value.status_code == 409

    class TestFindOne:
        """Tests for UserService.find_one."""

        def test_returns_user_when_found(
            self, service: UserService, mock_db: MagicMock
        ) -> None:
            user_id = uuid.uuid4()
            mock_user = MagicMock()
            mock_user.id = user_id
            mock_user.email = "test@example.com"
            mock_db.query.return_value.filter.return_value.first.return_value = (
                mock_user
            )

            result = service.find_one(user_id)

            assert result is not None

        def test_raises_not_found_when_missing(
            self, service: UserService, mock_db: MagicMock
        ) -> None:
            mock_db.query.return_value.filter.return_value.first.return_value = None

            with pytest.raises(HTTPException) as exc_info:
                service.find_one(uuid.uuid4())

            assert exc_info.value.status_code == 404
```

### Testing Logging and Sanitization

Verify that sensitive data is NOT logged:

```python
import structlog

class TestAuthService:
    """Tests for AuthService logging sanitization."""

    def test_login_logs_email_without_password(self, service, caplog) -> None:
        """Should log login attempt without password field."""
        login_data = {"email": "test@example.com", "password": "secret123"}

        service.login(login_data)

        # Verify password is NOT in any log output
        for record in caplog.records:
            assert "secret123" not in str(record.msg)
            assert "password" not in str(getattr(record, "payload", {}))

    def test_sanitize_for_log_removes_sensitive_keys(self) -> None:
        """Should strip sensitive keys from dict."""
        from my_project.utils.logging import sanitize_for_log

        data = {
            "email": "test@example.com",
            "password": "secret",
            "token": "abc123",
            "name": "Test",
        }

        result = sanitize_for_log(data)

        assert "email" in result
        assert "name" in result
        assert "password" not in result
        assert "token" not in result
```

### Testing Transactions

```python
class TestTransferFunds:
    """Tests for AccountService.transfer_funds."""

    def test_executes_transfer_successfully(
        self, service: AccountService, mock_db: MagicMock
    ) -> None:
        from_account = MagicMock(balance=500)
        to_account = MagicMock(balance=100)

        mock_db.query.return_value.filter.return_value.with_for_update.return_value.one.side_effect = [
            from_account,
            to_account,
        ]

        service.transfer_funds(uuid.uuid4(), uuid.uuid4(), 200)

        assert from_account.balance == 300
        assert to_account.balance == 300
        mock_db.commit.assert_called_once()

    def test_rolls_back_on_failure(
        self, service: AccountService, mock_db: MagicMock
    ) -> None:
        mock_db.query.return_value.filter.return_value.with_for_update.return_value.one.side_effect = Exception(
            "DB error"
        )

        with pytest.raises(Exception):
            service.transfer_funds(uuid.uuid4(), uuid.uuid4(), 200)

        mock_db.rollback.assert_called_once()
```

## Integration Testing

### Testing with Real Database

Use a real test database (PostgreSQL or SQLite) for integration tests:

```python
# tests/integration/test_user_repository.py
import pytest
from sqlalchemy.orm import Session
from my_project.models.user import User
from my_project.services.user_service import UserService
from my_project.schemas.user import CreateUserRequest


@pytest.mark.integration
class TestUserServiceIntegration:
    """Integration tests for UserService with real database."""

    @pytest.fixture
    def service(self, db_session: Session) -> UserService:
        return UserService(db=db_session)

    def test_creates_and_retrieves_user(self, service: UserService) -> None:
        create_dto = CreateUserRequest(
            email="test@example.com", name="Test User"
        )

        created = service.create(create_dto)
        assert created.id is not None

        retrieved = service.find_one(created.id)
        assert retrieved.email == "test@example.com"
        assert retrieved.name == "Test User"

    def test_enforces_unique_email_constraint(
        self, service: UserService
    ) -> None:
        dto = CreateUserRequest(email="test@example.com", name="User 1")
        service.create(dto)

        from fastapi import HTTPException

        with pytest.raises(HTTPException) as exc_info:
            service.create(
                CreateUserRequest(email="test@example.com", name="User 2")
            )
        assert exc_info.value.status_code == 409

    def test_find_all_with_pagination(self, service: UserService) -> None:
        for i in range(5):
            service.create(
                CreateUserRequest(email=f"user{i}@example.com", name=f"User {i}")
            )

        page = service.find_all(skip=0, limit=3)
        assert len(page) == 3

        page2 = service.find_all(skip=3, limit=3)
        assert len(page2) == 2
```

### Integration Test Database Configuration

For PostgreSQL integration tests, use a dedicated test database:

```python
# tests/conftest.py (extended for integration)
import os

INTEGRATION_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql://postgres:postgres@localhost:5432/myproject_test",
)


@pytest.fixture(scope="session")
def integration_engine():
    """Create engine for integration tests using real PostgreSQL."""
    from sqlalchemy import create_engine
    engine = create_engine(INTEGRATION_DATABASE_URL)
    Base.metadata.create_all(bind=engine)
    yield engine
    Base.metadata.drop_all(bind=engine)
    engine.dispose()


@pytest.fixture
def integration_db_session(integration_engine):
    """Provide a transactional session that rolls back after each test."""
    from sqlalchemy.orm import sessionmaker
    SessionLocal = sessionmaker(bind=integration_engine)
    session = SessionLocal()
    yield session
    session.rollback()
    session.close()
```

## E2E Testing

### Testing API Endpoints with TestClient

```python
# tests/e2e/test_users_api.py
import pytest
from fastapi.testclient import TestClient


@pytest.mark.e2e
class TestUsersAPI:
    """End-to-end tests for /users endpoints."""

    def test_create_user_with_valid_data(self, test_client: TestClient) -> None:
        response = test_client.post(
            "/users/",
            json={"email": "test@example.com", "name": "Test User"},
        )

        assert response.status_code == 201
        data = response.json()
        assert data["email"] == "test@example.com"
        assert data["name"] == "Test User"
        assert "id" in data

    def test_create_user_with_invalid_email(
        self, test_client: TestClient
    ) -> None:
        response = test_client.post(
            "/users/",
            json={"email": "invalid", "name": "Test User"},
        )

        assert response.status_code == 422

    def test_create_user_with_duplicate_email(
        self, test_client: TestClient
    ) -> None:
        test_client.post(
            "/users/",
            json={"email": "test@example.com", "name": "User 1"},
        )
        response = test_client.post(
            "/users/",
            json={"email": "test@example.com", "name": "User 2"},
        )

        assert response.status_code == 409

    def test_get_user_when_exists(self, test_client: TestClient) -> None:
        create_response = test_client.post(
            "/users/",
            json={"email": "test@example.com", "name": "Test User"},
        )
        user_id = create_response.json()["id"]

        response = test_client.get(f"/users/{user_id}")

        assert response.status_code == 200
        assert response.json()["id"] == user_id

    def test_get_user_when_not_found(self, test_client: TestClient) -> None:
        import uuid

        response = test_client.get(f"/users/{uuid.uuid4()}")

        assert response.status_code == 404

    def test_list_users_with_pagination(
        self, test_client: TestClient
    ) -> None:
        for i in range(5):
            test_client.post(
                "/users/",
                json={"email": f"user{i}@example.com", "name": f"User {i}"},
            )

        response = test_client.get("/users/?skip=0&limit=3")

        assert response.status_code == 200
        assert len(response.json()) == 3

    def test_update_user(self, test_client: TestClient) -> None:
        create_response = test_client.post(
            "/users/",
            json={"email": "test@example.com", "name": "Original"},
        )
        user_id = create_response.json()["id"]

        response = test_client.patch(
            f"/users/{user_id}",
            json={"name": "Updated"},
        )

        assert response.status_code == 200
        assert response.json()["name"] == "Updated"

    def test_delete_user(self, test_client: TestClient) -> None:
        create_response = test_client.post(
            "/users/",
            json={"email": "test@example.com", "name": "Test User"},
        )
        user_id = create_response.json()["id"]

        response = test_client.delete(f"/users/{user_id}")
        assert response.status_code == 204

        get_response = test_client.get(f"/users/{user_id}")
        assert get_response.status_code == 404
```

### Async E2E Testing with httpx

For testing async endpoints:

```python
import pytest
from httpx import AsyncClient, ASGITransport
from my_project.main import create_app


@pytest.mark.asyncio
class TestUsersAPIAsync:
    """Async E2E tests using httpx."""

    @pytest.fixture
    async def async_client(self, db_session):
        app = create_app()

        def _override_db():
            yield db_session

        app.dependency_overrides[get_db_session] = _override_db

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            yield client

    async def test_create_and_get_user(self, async_client: AsyncClient) -> None:
        response = await async_client.post(
            "/users/",
            json={"email": "test@example.com", "name": "Test"},
        )
        assert response.status_code == 201

        user_id = response.json()["id"]
        get_response = await async_client.get(f"/users/{user_id}")
        assert get_response.status_code == 200
```

## Testing Middleware

```python
# tests/unit/middleware/test_request_logging.py
import pytest
from starlette.testclient import TestClient
from fastapi import FastAPI
from my_project.middleware.request_logging import RequestLoggingMiddleware


class TestRequestLoggingMiddleware:
    """Tests for RequestLoggingMiddleware."""

    @pytest.fixture
    def app_with_middleware(self) -> FastAPI:
        app = FastAPI()
        app.add_middleware(RequestLoggingMiddleware)

        @app.get("/test")
        async def test_endpoint():
            return {"status": "ok"}

        return app

    def test_adds_request_id_to_response(
        self, app_with_middleware: FastAPI
    ) -> None:
        client = TestClient(app_with_middleware)

        response = client.get("/test")

        assert "x-request-id" in response.headers

    def test_preserves_provided_request_id(
        self, app_with_middleware: FastAPI
    ) -> None:
        client = TestClient(app_with_middleware)

        response = client.get(
            "/test", headers={"x-request-id": "custom-trace-123"}
        )

        assert response.headers["x-request-id"] == "custom-trace-123"

    def test_logs_request_details(
        self, app_with_middleware: FastAPI, caplog
    ) -> None:
        client = TestClient(app_with_middleware)

        with caplog.at_level("INFO"):
            client.get("/test")

        assert any("Request completed" in r.message for r in caplog.records)
```

## Using Factories for Test Data

```python
# tests/factories.py
import uuid
import factory
from my_project.models.user import User


class UserFactory(factory.Factory):
    class Meta:
        model = User

    id = factory.LazyFunction(uuid.uuid4)
    email = factory.Sequence(lambda n: f"user{n}@example.com")
    name = factory.Faker("name")
    role = "user"
    is_active = True
```

## Best Practices

1. **Isolation**: Each test should be independent -- use fixtures for setup, rollback DB in teardown
2. **Mocking**: Mock external dependencies (database, APIs, file system) in unit tests
3. **Cleanup**: Use pytest fixtures with `yield` for automatic cleanup
4. **Arrange-Act-Assert**: Structure tests clearly with blank lines between sections
5. **Test Behavior**: Test what the code does, not how it does it
6. **Security**: Verify sensitive data sanitization in logs
7. **Error Cases**: Test both success and failure paths (especially HTTP status codes)
8. **Realistic Data**: Use factories (`factory_boy`) and realistic test data
9. **Performance**: Keep unit tests fast (<100ms each), mark slow tests with `@pytest.mark.integration`
10. **Type Hints**: All test functions should have return type `-> None`
11. **Markers**: Use `@pytest.mark.integration` and `@pytest.mark.e2e` to separate test tiers
12. **Run Tiers Separately**: `uv run pytest -m "not integration and not e2e"` for fast feedback
