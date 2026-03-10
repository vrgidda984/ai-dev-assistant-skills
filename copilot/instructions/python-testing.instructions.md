---
applyTo: "tests/**/*.py,**/test_*.py,**/conftest.py"
---

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
    class TestCreate:
        def test_creates_user_successfully(self, ...) -> None: ...
        def test_raises_conflict_when_email_exists(self, ...) -> None: ...
```

Pattern: `test_<expected_behavior>_when_<condition>` or `test_<action>_<outcome>`.

## Test Configuration

### conftest.py (Shared Fixtures)

```python
import pytest
from collections.abc import Generator
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, StaticPool
from sqlalchemy.orm import sessionmaker, Session
from my_project.main import create_app
from my_project.dependencies import get_db_session
from my_project.models.base import Base

TEST_DATABASE_URL = "sqlite://"
engine = create_engine(TEST_DATABASE_URL, connect_args={"check_same_thread": False}, poolclass=StaticPool)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(autouse=True)
def _setup_db() -> Generator[None, None, None]:
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def db_session() -> Generator[Session, None, None]:
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.rollback()
        session.close()

@pytest.fixture
def test_client(db_session: Session) -> TestClient:
    app = create_app()
    def _override_db() -> Generator[Session, None, None]:
        yield db_session
    app.dependency_overrides[get_db_session] = _override_db
    return TestClient(app)
```

## Unit Testing Services

Always mock the database session in unit tests:

```python
class TestUserService:
    @pytest.fixture
    def mock_db(self) -> MagicMock:
        return MagicMock()

    @pytest.fixture
    def service(self, mock_db: MagicMock) -> UserService:
        return UserService(db=mock_db)

    class TestCreate:
        def test_creates_user_successfully(self, service, mock_db) -> None:
            create_dto = CreateUserRequest(email="test@example.com", name="Test User")
            mock_db.query.return_value.filter.return_value.first.return_value = None
            result = service.create(create_dto)
            mock_db.add.assert_called_once()
            mock_db.commit.assert_called_once()

        def test_raises_conflict_when_email_exists(self, service, mock_db) -> None:
            mock_db.query.return_value.filter.return_value.first.return_value = MagicMock()
            with pytest.raises(HTTPException) as exc_info:
                service.create(CreateUserRequest(email="test@example.com", name="Test"))
            assert exc_info.value.status_code == 409
```

### Testing Logging and Sanitization

```python
class TestAuthService:
    def test_login_logs_email_without_password(self, service, caplog) -> None:
        login_data = {"email": "test@example.com", "password": "secret123"}
        service.login(login_data)
        for record in caplog.records:
            assert "secret123" not in str(record.msg)
```

## E2E Testing

```python
@pytest.mark.e2e
class TestUsersAPI:
    def test_create_user_with_valid_data(self, test_client: TestClient) -> None:
        response = test_client.post("/users/", json={"email": "test@example.com", "name": "Test User"})
        assert response.status_code == 201
        assert "id" in response.json()

    def test_create_user_with_invalid_email(self, test_client: TestClient) -> None:
        response = test_client.post("/users/", json={"email": "invalid", "name": "Test User"})
        assert response.status_code == 422
```

## Using Factories for Test Data

```python
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

1. **Isolation**: Each test should be independent — use fixtures for setup
2. **Mocking**: Mock external dependencies in unit tests
3. **Cleanup**: Use pytest fixtures with `yield` for automatic cleanup
4. **Arrange-Act-Assert**: Structure tests clearly
5. **Test Behavior**: Test what the code does, not how it does it
6. **Security**: Verify sensitive data sanitization in logs
7. **Error Cases**: Test both success and failure paths
8. **Realistic Data**: Use factories (`factory_boy`)
9. **Performance**: Keep unit tests fast (<100ms each)
10. **Type Hints**: All test functions should have return type `-> None`
11. **Markers**: Use `@pytest.mark.integration` and `@pytest.mark.e2e`
12. **Run Tiers Separately**: `uv run pytest -m "not integration and not e2e"` for fast feedback
