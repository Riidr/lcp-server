# LCP Server — PR Review Rules

## Security and Cryptography

This is a DRM server that handles content encryption and license signing. Crypto mistakes are critical.

- Flag any use of custom crypto implementations (e.g., manual AES, custom padding). All encryption MUST use `pkg/crypto/` (`NewAESEncrypter_CONTENT_KEY`, `NewAESEncrypter_USER_KEY_CHECK`, `NewAESEncrypter_FIELDS`).
- Flag hardcoded keys, secrets, passwords, or credentials anywhere in Go source files. Secrets must come from config, environment variables, or Docker secrets (`/run/secrets/*`).
- Flag any changes to AES key sizes, cipher modes, or padding schemes in `pkg/crypto/`. The project uses AES-256-CBC — changes require careful review.
- Flag any new route in `cmd/lcpserver/router.go` that is not placed inside the correct auth middleware group:
  - Public routes (no auth): only `/health`, `/status/{id}`, `/register/{id}`, `/renew/{id}`, `/return/{id}`
  - Private routes (Basic Auth): `/publications`, `/licenseinfo`, `/licenses`, `/revoke`
  - Dashboard routes (JWT): `/dashdata/*`
- Flag any API response that exposes `EncryptionKey` from the Publication model. This field must never appear in JSON responses.
- Flag any changes to X.509 certificate loading or signature verification in `pkg/sign/`.

## License State Machine Integrity

The license lifecycle has strict state transitions. Invalid transitions break the DRM protocol.

Valid transitions:
- `ready` -> `active` (Register)
- `ready` -> `cancelled` (Revoke)
- `ready` -> `expired` (automatic, End < now)
- `active` -> `expired` (automatic, End < now)
- `active` -> `returned` (Return)
- `active` -> `revoked` (Revoke)
- `expired` -> `active` (Renew, only if `AllowRenewOnExpiredLicenses` is enabled)

When reviewing changes to `pkg/lic/status_doc.go`:
- Flag any code that transitions a license to a status not permitted by the state machine above.
- Flag any direct assignment to `license.Status` outside of the Register, Renew, Return, and Revoke functions.
- Flag any status change that does not create a corresponding event (`EVENT_REGISTER`, `EVENT_RENEW`, `EVENT_RETURN`, `EVENT_REVOKE`, `EVENT_CANCEL`).
- Flag changes to Register that allow statuses other than `ready` or `active`.
- Flag changes to Renew that allow statuses other than `active` (or `expired` when config explicitly allows it).
- Flag changes to Return that allow statuses other than `active`.

## Database and GORM Patterns

The project uses GORM with AutoMigrate (no versioned migrations). Unbounded queries and soft-delete leaks are the main risks.

- Flag any `.Find()` or `.Where().Find()` query without a `.Limit()`. All queries must be bounded:
  - List endpoints: max 1000 results
  - Event queries: max 500 results
- Flag any use of `.Unscoped()` without an explanatory comment. `Unscoped()` includes soft-deleted records, which can leak data that should be hidden.
- Flag raw SQL strings (`.Raw()`, `.Exec()` with SQL). Use GORM query builder methods instead. Exception: SQLite PRAGMAs in `pkg/stor/store.go` are acceptable.
- Flag any new list/search endpoint in `pkg/api/` that does not use the pagination middleware (extracting `PageKey`/`PerPageKey` from context).
- Flag changes to GORM model struct tags (`gorm:"..."`) that alter column types, remove indexes, or drop fields. Since the project uses AutoMigrate with no versioned migrations, destructive schema changes can cause data loss.

## Error Handling

- Flag swallowed errors: `if err != nil { }` blocks that take no action (no log, no return, no render).
- Flag HTTP handler errors that do not use the RFC 7807 error renderers: `ErrInvalidRequest(err)`, `ErrServer(err)`, `ErrNotFound`. Do not return raw `http.Error()` or `json.NewEncoder` error responses.
- Flag missing early return after `render.Render(w, r, Err...)` calls. Without a `return`, the handler continues executing after the error response.
- Flag error logging that does not include context about what operation failed. Prefer `log.Errorf("error doing X: %v", err)` over `log.Errorf("%v", err)`.

## API and Route Conventions

- Flag new request/response structs that use camelCase or PascalCase in `json:"..."` tags. This project uses `snake_case` for all JSON field names.
- Flag new request structs that are missing `validate:"..."` tags. All required fields must have `validate:"required"`, UUIDs must have `validate:"uuid"`, URLs must have `validate:"url"`.
- Flag responses that return LCP licenses without Content-Type `application/vnd.readium.lcp.license.v1.0+json` or status documents without `application/vnd.readium.license.status.v1.0+json`.
- Flag new endpoints that do not follow the existing handler pattern: method on `*APICtrl`, using `render.Bind` for input and `render.Render`/`render.RenderList` for output.

## Go Conventions

- Flag new `.go` files missing the copyright header: `// Copyright YYYY European Digital Reading Lab. All rights reserved.`
- Flag imports that are not grouped with blank-line separators: standard library, then third-party, then local (`github.com/edrlab/lcp-server/...`).
- Flag new constants that do not use `UPPER_SNAKE_CASE` (e.g., `StatusReady` instead of `STATUS_READY`).
- Flag logrus imported without the `log` alias: must be `log "github.com/sirupsen/logrus"`.
- Flag `log.Info()` or `log.Infof()` calls. This project uses `log.Println()` for info-level messages.

## Testing

- Flag changes to business logic in `pkg/lic/`, `pkg/api/`, or `pkg/stor/` that do not include corresponding test updates or additions.
- Flag test files that use an external assertion library (e.g., testify). This project uses standard library `t.Errorf()` and `t.Fatalf()` only.
- Flag test data that uses hardcoded UUIDs or static strings instead of generated values (`uuid.New().String()`, `faker`).
