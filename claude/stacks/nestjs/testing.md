# NestJS Testing Standards

## Test Pyramid

- Unit: 70% (services, business logic)
- Integration: 20% (modules, database interactions)
- E2E: 10% (API flows, complete user journeys)

## Coverage Requirements

- Statements: 80%
- Branches: 75%
- Functions: 80%
- Lines: 80%

## Naming Convention

```typescript
describe('ServiceName', () => {
  describe('methodName', () => {
    it('should [expected] when [condition]', () => {});
  });
});
```

## Unit Testing Services

### Testing Services with Prisma

Always mock PrismaService in unit tests:

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { UserService } from './user.service';
import { PrismaService } from '../prisma/prisma.service';

describe('UserService', () => {
  let service: UserService;
  let prisma: PrismaService;

  const mockPrismaService = {
    user: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    $transaction: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UserService,
        {
          provide: PrismaService,
          useValue: mockPrismaService,
        },
      ],
    }).compile();

    service = module.get<UserService>(UserService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('create', () => {
    it('should create a user successfully', async () => {
      const createUserDto = { email: 'test@example.com', name: 'Test User' };
      const expectedUser = { id: '123', ...createUserDto };

      mockPrismaService.user.create.mockResolvedValue(expectedUser);

      const result = await service.create(createUserDto);

      expect(result).toEqual(expectedUser);
      expect(prisma.user.create).toHaveBeenCalledWith({ data: createUserDto });
    });

    it('should throw InternalServerErrorException when creation fails', async () => {
      mockPrismaService.user.create.mockRejectedValue(new Error('DB Error'));

      await expect(service.create({ email: 'test@example.com' }))
        .rejects
        .toThrow(InternalServerErrorException);
    });
  });

  describe('findOne', () => {
    it('should return user when found', async () => {
      const expectedUser = { id: '123', email: 'test@example.com' };
      mockPrismaService.user.findUnique.mockResolvedValue(expectedUser);

      const result = await service.findOne('123');

      expect(result).toEqual(expectedUser);
      expect(prisma.user.findUnique).toHaveBeenCalledWith({
        where: { id: '123' },
      });
    });

    it('should throw NotFoundException when user not found', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue(null);

      await expect(service.findOne('999'))
        .rejects
        .toThrow(NotFoundException);
    });
  });
});
```

### Testing Logging and Sanitization

Verify that sensitive data is NOT logged:

```typescript
import { Logger } from '@nestjs/common';

describe('AuthService', () => {
  let service: AuthService;
  let loggerSpy: jest.SpyInstance;

  beforeEach(() => {
    loggerSpy = jest.spyOn(Logger.prototype, 'log').mockImplementation();
  });

  afterEach(() => {
    loggerSpy.mockRestore();
  });

  describe('login', () => {
    it('should log login attempt without password', async () => {
      const loginDto = { email: 'test@example.com', password: 'secret123' };

      await service.login(loginDto);

      expect(loggerSpy).toHaveBeenCalled();
      const logCall = loggerSpy.mock.calls[0];
      const logContext = logCall[1];

      // Verify password is NOT in logs
      expect(logContext.payload).not.toHaveProperty('password');
      expect(JSON.stringify(logContext)).not.toContain('secret123');

      // Verify email IS in logs
      expect(logContext.payload.email).toBe('test@example.com');
    });
  });
});
```

### Testing Transactions

```typescript
describe('transferFunds', () => {
  it('should execute transaction successfully', async () => {
    const transaction = jest.fn().mockImplementation(async (fn) => fn(prisma));
    mockPrismaService.$transaction = transaction;

    await service.transferFunds('user1', 'user2', 100);

    expect(transaction).toHaveBeenCalled();
    expect(prisma.account.update).toHaveBeenCalledTimes(2);
  });

  it('should rollback on transaction failure', async () => {
    mockPrismaService.$transaction.mockRejectedValue(new Error('Transaction failed'));

    await expect(service.transferFunds('user1', 'user2', 100))
      .rejects
      .toThrow();
  });
});
```

## Integration Testing

### Testing Modules with Real Database

Use test database for integration tests:

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from '../prisma/prisma.service';
import { UserModule } from './user.module';
import { UserService } from './user.service';

describe('UserModule (Integration)', () => {
  let module: TestingModule;
  let service: UserService;
  let prisma: PrismaService;

  beforeAll(async () => {
    module = await Test.createTestingModule({
      imports: [UserModule],
    }).compile();

    service = module.get<UserService>(UserService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  beforeEach(async () => {
    // Clean database before each test
    await prisma.user.deleteMany();
  });

  afterAll(async () => {
    await prisma.$disconnect();
    await module.close();
  });

  it('should create and retrieve user', async () => {
    const createDto = { email: 'test@example.com', name: 'Test' };

    const created = await service.create(createDto);
    expect(created.id).toBeDefined();

    const retrieved = await service.findOne(created.id);
    expect(retrieved).toMatchObject(createDto);
  });
});
```

## E2E Testing

### Testing Controllers and API Endpoints

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../app.module';
import { PrismaService } from '../prisma/prisma.service';

describe('UserController (E2E)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    await app.init();

    prisma = app.get<PrismaService>(PrismaService);
  });

  beforeEach(async () => {
    await prisma.user.deleteMany();
  });

  afterAll(async () => {
    await prisma.$disconnect();
    await app.close();
  });

  describe('POST /users', () => {
    it('should create user with valid data', () => {
      return request(app.getHttpServer())
        .post('/users')
        .send({ email: 'test@example.com', name: 'Test User' })
        .expect(201)
        .expect((res) => {
          expect(res.body).toHaveProperty('id');
          expect(res.body.email).toBe('test@example.com');
        });
    });

    it('should return 400 with invalid email', () => {
      return request(app.getHttpServer())
        .post('/users')
        .send({ email: 'invalid', name: 'Test User' })
        .expect(400);
    });
  });

  describe('GET /users/:id', () => {
    it('should return user when found', async () => {
      const user = await prisma.user.create({
        data: { email: 'test@example.com', name: 'Test' },
      });

      return request(app.getHttpServer())
        .get(`/users/${user.id}`)
        .expect(200)
        .expect((res) => {
          expect(res.body.id).toBe(user.id);
        });
    });

    it('should return 404 when user not found', () => {
      return request(app.getHttpServer())
        .get('/users/non-existent-id')
        .expect(404);
    });
  });
});
```

## Testing Middleware

```typescript
describe('LoggingMiddleware', () => {
  let middleware: LoggingMiddleware;
  let req: Partial<Request>;
  let res: Partial<Response>;
  let next: jest.Mock;
  let loggerSpy: jest.SpyInstance;

  beforeEach(() => {
    middleware = new LoggingMiddleware();
    req = { method: 'GET', url: '/users', headers: {} };
    res = { statusCode: 200 };
    next = jest.fn();
    loggerSpy = jest.spyOn(Logger.prototype, 'log').mockImplementation();
  });

  it('should log request with traceId', () => {
    req.headers = { 'x-trace-id': 'trace-123' };

    middleware.use(req as Request, res as Response, next);

    expect(loggerSpy).toHaveBeenCalledWith(
      expect.any(String),
      expect.objectContaining({ traceId: 'trace-123' })
    );
    expect(next).toHaveBeenCalled();
  });
});
```

## Testing Guards, Interceptors, Pipes, and Filters

Use `overrideGuard()`, `overrideInterceptor()`, `overridePipe()`, `overrideFilter()` for test replacements:

```typescript
const module = await Test.createTestingModule({
  imports: [AppModule],
})
  .overrideGuard(JwtAuthGuard).useValue({ canActivate: () => true })
  .overrideInterceptor(LoggingInterceptor).useValue({ intercept: (_, next) => next.handle() })
  .compile();
```

For globally registered enhancers (via `APP_*` tokens), use `useExisting` in the provider to make them overridable:

```typescript
// In module — makes the guard overridable in tests
{ provide: APP_GUARD, useExisting: JwtAuthGuard }

// In test
.overrideProvider(JwtAuthGuard).useValue({ canActivate: () => true })
```

## Auto-Mocking with useMocker

For services with many dependencies, use `.useMocker()` to auto-create mocks:

```typescript
const module = await Test.createTestingModule({
  providers: [UserService],
})
  .useMocker((token) => {
    if (token === PrismaService) {
      return { user: { findUnique: jest.fn(), create: jest.fn() } };
    }
    if (typeof token === 'function') {
      return createMock(token); // using @golevelup/ts-jest or similar
    }
  })
  .compile();
```

## Best Practices

1. **Isolation**: Each test should be independent
2. **Mocking**: Mock external dependencies (database, APIs) in unit tests
3. **Cleanup**: Always clean up test data in `afterEach` or `afterAll`
4. **Arrange-Act-Assert**: Structure tests clearly
5. **Test Behavior**: Test what the code does, not how it does it
6. **Security**: Verify sensitive data sanitization in logs
7. **Error Cases**: Test both success and failure paths
8. **Realistic Data**: Use realistic test data, avoid magic numbers
9. **Performance**: Keep unit tests fast (<100ms each)
10. **Transactions**: Wrap test database operations in transactions when possible
11. **Always call `.compile()`** before retrieving instances with `module.get()`
12. **Use `resolve()` not `get()`** for request-scoped or transient providers
