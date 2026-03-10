---
applyTo: "**/*.spec.ts,**/*.e2e-spec.ts,test/**/*.ts"
---

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
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<UserService>(UserService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  afterEach(() => { jest.clearAllMocks(); });

  describe('create', () => {
    it('should create a user successfully', async () => {
      const createUserDto = { email: 'test@example.com', name: 'Test User' };
      const expectedUser = { id: '123', ...createUserDto };
      mockPrismaService.user.create.mockResolvedValue(expectedUser);

      const result = await service.create(createUserDto);

      expect(result).toEqual(expectedUser);
      expect(prisma.user.create).toHaveBeenCalledWith({ data: createUserDto });
    });
  });
});
```

### Testing Logging and Sanitization

Verify that sensitive data is NOT logged:

```typescript
import { Logger } from '@nestjs/common';

describe('AuthService', () => {
  let loggerSpy: jest.SpyInstance;

  beforeEach(() => {
    loggerSpy = jest.spyOn(Logger.prototype, 'log').mockImplementation();
  });

  afterEach(() => { loggerSpy.mockRestore(); });

  it('should log login attempt without password', async () => {
    const loginDto = { email: 'test@example.com', password: 'secret123' };
    await service.login(loginDto);

    const logContext = loggerSpy.mock.calls[0][1];
    expect(logContext.payload).not.toHaveProperty('password');
    expect(JSON.stringify(logContext)).not.toContain('secret123');
  });
});
```

## Integration Testing

Use test database for integration tests:

```typescript
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

  beforeEach(async () => { await prisma.user.deleteMany(); });
  afterAll(async () => { await prisma.$disconnect(); await module.close(); });

  it('should create and retrieve user', async () => {
    const created = await service.create({ email: 'test@example.com', name: 'Test' });
    const retrieved = await service.findOne(created.id);
    expect(retrieved).toMatchObject({ email: 'test@example.com' });
  });
});
```

## E2E Testing

```typescript
describe('UserController (E2E)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const moduleFixture = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    await app.init();
    prisma = app.get<PrismaService>(PrismaService);
  });

  beforeEach(async () => { await prisma.user.deleteMany(); });
  afterAll(async () => { await prisma.$disconnect(); await app.close(); });

  it('should create user with valid data', () => {
    return request(app.getHttpServer())
      .post('/users')
      .send({ email: 'test@example.com', name: 'Test User' })
      .expect(201)
      .expect((res) => { expect(res.body).toHaveProperty('id'); });
  });

  it('should return 400 with invalid email', () => {
    return request(app.getHttpServer())
      .post('/users')
      .send({ email: 'invalid', name: 'Test User' })
      .expect(400);
  });
});
```

## Best Practices

1. **Isolation**: Each test should be independent
2. **Mocking**: Mock external dependencies in unit tests
3. **Cleanup**: Always clean up test data in `afterEach` or `afterAll`
4. **Arrange-Act-Assert**: Structure tests clearly
5. **Test Behavior**: Test what the code does, not how it does it
6. **Security**: Verify sensitive data sanitization in logs
7. **Error Cases**: Test both success and failure paths
8. **Realistic Data**: Use realistic test data, avoid magic numbers
9. **Performance**: Keep unit tests fast (<100ms each)
10. **Transactions**: Wrap test database operations in transactions when possible
