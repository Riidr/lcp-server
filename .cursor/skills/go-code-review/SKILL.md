---
name: go-code-review
description: Review Go code for quality, security, and adherence to LCP Server conventions. Use when reviewing pull requests, examining code changes, or when the user asks for a code review.
---

# Go Code Review — LCP Server

## Review Checklist

Copy and work through:

```
- [ ] Correctness & edge cases
- [ ] Error handling (no swallowed errors)
- [ ] Security (crypto, auth, input validation)
- [ ] Coding conventions (see below)
- [ ] Database patterns (GORM usage)
- [ ] Test coverage
```

## Severity Levels

- **Critical**: Must fix — security issues, data loss, broken DRM, swallowed errors
- **Warning**: Should fix — convention violations, missing validation, poor error messages
- **Suggestion**: Nice to have — readability, naming, minor optimizations

## Convention Checks

### Imports
- Grouped: stdlib → third-party → local (`github.com/edrlab/lcp-server/...`)
- Logrus aliased as `log` (some files use stdlib `log` instead — don't confuse them)

### Naming
- Constants: `UPPER_SNAKE_CASE` (`STATUS_READY`, not `StatusReady`)
- Constructors: `New` prefix (`NewAPICtrl`)
- Unexported store types: `camelCase` (`publicationStore`, not `PublicationStore`)

### Error Handling
- Every error checked immediately, early return
- HTTP errors use `ErrInvalidRequest`, `ErrServer`, `ErrNotFound` (RFC 7807)
- Log errors with `log.Errorf("context: %v", err)` before rendering

### Struct Tags
- JSON: `snake_case` with `omitempty` for optional fields
- GORM: explicit types and indexes (`gorm:"type:varchar(100);uniqueIndex"`)
- Validator: `validate:"required,uuid"` using `go-playground/validator/v10`

## Security Checks

- No hardcoded secrets or keys
- User input validated and bounded (query results capped at 1000)
- Crypto operations use project's `pkg/crypto` (AES-256-CBC, not custom implementations)
- Soft-deleted records not leaked (use `Unscoped()` explicitly and intentionally)
- Device counts and event limits enforced (max 500 events)
- License state transitions follow the state machine (see lcp-protocol skill)
- Basic Auth on private routes, JWT on dashboard routes

## Database Checks

- Pagination uses `Offset`/`Limit`, not unbounded queries
- Soft deletes: `DeletedAt.Valid` checked where needed
- `Unscoped()` only used with a comment explaining why
- No raw SQL — use GORM query builder
- Transactions for multi-step operations

## Test Checks

- New logic has corresponding `_test.go`
- Uses in-memory SQLite (`sqlite3://file::memory:?cache=shared`)
- Assertions use `t.Errorf`/`t.Fatalf` (no assertion libraries)
- Test data from `faker` or `uuid.New()`, not hardcoded values
