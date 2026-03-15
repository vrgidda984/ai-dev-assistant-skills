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

## Request Pipeline

Execution order: Middleware → Guards → Interceptors (pre) → Pipes → Handler → Interceptors (post) → Exception Filters

- Use **middleware** for authentication (token validation)
- Use **guards** for authorization (permission checks)
- Use **pipes** for input validation/transformation
- Use **interceptors** for cross-cutting concerns (logging, caching, response mapping)

## Provider Scopes

- `DEFAULT` (Singleton) — use for most services
- `REQUEST` — new instance per request; adds ~5% latency; bubbles up dependency chain
- `TRANSIENT` — new instance per injection; does NOT bubble scope
- Never use request-scoped providers with WebSocket Gateways or Cron controllers

## Global Registration

Prefer module-based registration via `APP_GUARD`, `APP_FILTER`, `APP_PIPE`, `APP_INTERCEPTOR` tokens over `app.useGlobal*()` — enables DI and testability.

## Configuration

- Use `ConfigModule.forRoot({ isGlobal: true, cache: true })` — avoid importing in every module
- Always validate env vars at startup with class-validator (`validate` function + `plainToInstance` + `validateSync`)
- Use typed ConfigService: `this.configService.get<string>('KEY', { infer: true })`
- Runtime env vars take precedence over `.env` values

## Dynamic Modules

Use `forRoot()` for global config (once in AppModule), `forFeature()` for per-module registration.

## Custom Decorators

Use `Reflector.createDecorator<T>()` for type-safe metadata decorators (e.g., `@Roles()`, `@Public()`).

## Code Standards

### Controllers
- @ApiTags, @ApiOperation, @ApiResponse decorators
- Validation pipes on all inputs
- Thin controllers — delegate to services
- Declare parameterized routes AFTER static routes
- Use `@Param()`, `@Body()`, `@Query()` — avoid raw `@Req()`
- Never use `@Res()` directly — breaks interceptors and serialization

### Services
- Logger: `private readonly logger = new Logger(ServiceName.name)`
- Throw NestJS exceptions (NotFoundException, ConflictException, etc.)
- Transactions for multi-entity operations
- Follow structured logging standards (see [Logging](#logging) section)

### DTOs
- Use **classes**, not interfaces — classes enable runtime validation
- class-validator on all fields
- @Transform for sanitization
- PartialType/OmitType for updates
- @Expose() in response DTOs (requires `class-transformer` + `ClassSerializerInterceptor`)

### Modules
- Use `exports` as the module's public API
- Use `@Global()` sparingly — only in root/core module
- Never register the same provider in multiple modules

### Guards
- Implement `CanActivate`; use for authorization, not authentication
- Throw `UnauthorizedException`/`ForbiddenException` with messages, don't just return `false`

### Pipes
- Use built-in pipes first: `ValidationPipe`, `ParseIntPipe`, `ParseUUIDPipe`, `DefaultValuePipe`
- Register global `ValidationPipe` via `APP_PIPE` with `whitelist: true`, `transform: true`

### Exception Handling
- Use built-in exceptions: `BadRequestException`, `NotFoundException`, `ForbiddenException`, etc.
- Custom exceptions must extend `HttpException`
- Use `cause` parameter for error chaining

### Entities
- UUID primary keys
- @Index on query columns
- Soft deletes with `deletedAt DateTime?` field and query filters

### Database (Prisma ORM)
- **Schema**: Define in `prisma/schema.prisma`
- **Client**: Inject PrismaService via DI
- **Transactions**: Use `prisma.$transaction()` for multi-model operations
- **Migrations**: `prisma migrate dev` for development, `prisma migrate deploy` for production
- **NEVER** auto-apply schema changes in production — always use `prisma migrate deploy`

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
