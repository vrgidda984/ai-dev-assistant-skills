---
applyTo: "src/**/*.ts,src/**/*.module.ts,src/**/*.controller.ts,src/**/*.service.ts"
---

# NestJS Backend Development

## Core Principles

- **Type Safety**: TypeScript strict mode
- **Modular Architecture**: Feature-based modules
- **Dependency Injection**: NestJS DI only
- **Fail Fast**: Validate early, meaningful exceptions
- **Documentation**: Swagger on every endpoint
- **Middleware**: Express middleware via @nestjs/platform-express
- **ORM**: Prisma for type-safe database access

## Project Structure

```
src/
├── main.ts
├── app.module.ts
├── modules/
│   └── [feature]/
│       ├── [feature].module.ts
│       ├── [feature].controller.ts
│       ├── [feature].service.ts
│       ├── dto/
│       ├── entities/
│       └── __tests__/
├── common/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   └── decorators/
└── config/
```

## Naming Conventions

### Casing Quick Reference

| What | Casing | Example |
|------|--------|---------|
| File names | kebab-case | `create-user.dto.ts` |
| Directories (domain) | kebab-case, singular | `user/`, `order-item/` |
| Directories (shared) | kebab-case, plural | `guards/`, `pipes/` |
| Classes | PascalCase + suffix | `UsersController`, `CreateUserDto` |
| Interfaces | PascalCase (no `I` prefix) | `JwtPayload` |
| Enums | PascalCase | `UserRole` |
| Enum members | UPPER_SNAKE_CASE | `ADMIN` |
| Enum values (string) | lowercase | `'admin'` |
| Constants | UPPER_SNAKE_CASE | `MAX_RETRY_ATTEMPTS` |
| Environment vars | UPPER_SNAKE_CASE | `DATABASE_URL` |
| Methods / functions | camelCase | `findOneByEmail()` |
| Variables / properties | camelCase | `firstName` |
| Booleans | camelCase with prefix | `isActive`, `hasRole`, `canDelete` |
| Route paths | kebab-case, plural nouns | `/user-profiles` |
| Entity classes | PascalCase, singular | `User` |
| DB table names | snake_case, plural | `users`, `order_items` |
| DB column names | snake_case | `first_name` |
| Event names (emitter) | dot.notation | `'user.created'` |
| Test files (unit) | `*.spec.ts` | `users.service.spec.ts` |
| Test files (e2e) | `*.e2e-spec.ts` | `users.e2e-spec.ts` |

### File Naming

Pattern: `<name>.<type>.ts` — kebab-case, dot-separated by type.

| Type | Pattern | Example |
|------|---------|---------|
| Controller | `<name>.controller.ts` | `users.controller.ts` |
| Service | `<name>.service.ts` | `users.service.ts` |
| Module | `<name>.module.ts` | `users.module.ts` |
| Guard | `<name>.guard.ts` | `jwt-auth.guard.ts` |
| Interceptor | `<name>.interceptor.ts` | `logging.interceptor.ts` |
| Filter | `<name>.filter.ts` | `http-exception.filter.ts` |
| Pipe | `<name>.pipe.ts` | `validation.pipe.ts` |
| Middleware | `<name>.middleware.ts` | `logger.middleware.ts` |
| Decorator | `<name>.decorator.ts` | `current-user.decorator.ts` |
| DTO | `<action>-<entity>.dto.ts` | `create-user.dto.ts` |
| Entity | `<name>.entity.ts` | `user.entity.ts` |

### Class Naming

PascalCase with a type suffix. Controllers and services use **plural** names; entities use **singular**.

| Type | Convention | Example |
|------|-----------|---------|
| Controller | `<Plural>Controller` | `UsersController` |
| Service | `<Plural>Service` | `UsersService` |
| Module | `<Plural>Module` | `UsersModule` |
| Guard | `<Name>Guard` | `JwtAuthGuard` |
| DTO | `<Action><Entity>Dto` | `CreateUserDto` |
| Entity | `<Singular>` | `User`, `ProductCategory` |
| Event | `<Entity><PastVerb>Event` | `UserCreatedEvent` |

### Method Naming

camelCase. Do not duplicate class context — in `UsersService`, use `findOne()` not `findOneUser()`.

**Standard CRUD methods**:

| HTTP | Route | Controller | Service |
|------|-------|-----------|---------|
| POST / | Create | `create()` | `create()` |
| GET / | List | `findAll()` | `findAll()` |
| GET /:id | Read | `findOne()` | `findOne()` |
| PATCH /:id | Update | `update()` | `update()` |
| DELETE /:id | Remove | `remove()` | `remove()` |

### Route Paths

- Plural nouns, kebab-case, lowercase: `/users`, `/product-categories`
- No verbs in paths — the HTTP method conveys the action
- Nested resources for relationships: `/users/:userId/orders`

## Code Standards

### Controllers
- @ApiTags, @ApiOperation, @ApiResponse decorators
- Validation pipes on all inputs
- Thin controllers — delegate to services

### Services
- Logger: `private readonly logger = new Logger(ServiceName.name)`
- Throw NestJS exceptions (NotFoundException, ConflictException, etc.)
- Transactions for multi-entity operations
- Follow structured logging standards (see Logging section below)

### DTOs
- class-validator on all fields
- @Transform for sanitization
- PartialType/OmitType for updates
- @Expose() in response DTOs

### Entities
- UUID primary keys
- @Index on query columns
- Soft deletes with @DeleteDateColumn

### Database (Prisma ORM)
- **Schema**: Define in `prisma/schema.prisma`
- **Client**: Inject PrismaService via DI
- **Transactions**: Use `prisma.$transaction()` for multi-model operations
- **Migrations**: `prisma migrate dev` for development, `prisma migrate deploy` for production

### Logging

**Standard Log Structure**:

```typescript
interface LogContext {
  action: string;              // Operation identifier
  service: string;             // Service/class name
  userId?: string;
  resourceId?: string;
  traceId?: string;
  payload?: Record<string, any>;   // Sanitize sensitive fields
  response?: Record<string, any>;
  duration?: number;
  error?: { message: string; code?: string; stack?: string; };
  metadata?: Record<string, any>;
}
```

**Sensitive Data Sanitization**:

CRITICAL: Never log sensitive information. Always sanitize before logging.

**Always Exclude from Logs**:
- `password`, `passwordHash`, `currentPassword`, `newPassword`
- `token`, `accessToken`, `refreshToken`, `apiKey`, `secret`
- `creditCard`, `cvv`, `cardNumber`, `ssn`, `taxId`
- `privateKey`, `secretKey`, `encryptionKey`
- Full request/response bodies without filtering

### PrismaService Setup

```typescript
// src/prisma/prisma.service.ts
@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  async onModuleInit() { await this.$connect(); }
  async onModuleDestroy() { await this.$disconnect(); }
}

// src/prisma/prisma.module.ts
@Global()
@Module({ providers: [PrismaService], exports: [PrismaService] })
export class PrismaModule {}
```
