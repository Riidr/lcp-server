---
name: lcp-protocol
description: Readium LCP/LSD protocol domain knowledge — license lifecycle, status transitions, device registration, renewal, return, revocation, encryption flows. Use when working on license generation, status documents, DRM logic, or any code in pkg/lic/ or pkg/api/ that touches licenses.
---

# LCP Protocol & License Lifecycle

## License Status State Machine

```
         Register           Return
ready ──────────► active ──────────► returned
  │                 │
  │ Revoke          │ Revoke
  ▼                 ▼
cancelled         revoked

  ready ──► expired  (automatic, when End < now)
  active ──► expired (automatic, when End < now)
  expired ──► active (Renew, only if AllowRenewOnExpiredLicenses)
```

**Statuses**: `ready`, `active`, `expired`, `returned`, `revoked`, `cancelled`

## Operations and Rules

### Register (`POST /register/{licenseID}`)
- License must be `ready` or `active`
- Device must not already be registered (check existing register events)
- `ready` → `active`; `active` stays `active`
- Increments `DeviceCount`, creates `EVENT_REGISTER`
- Duplicate registration: silently returns existing status doc (no error, no event)

### Renew (`PUT /renew/{licenseID}`)
- License must be `active` (or `expired` if config allows)
- License must have an `End` date
- Device must have previously registered
- New end date: request param > `RenewDefaultDays` from now > 7 days from now
- Clamped to `MaxEnd` if exceeded
- Creates `EVENT_RENEW`

### Return (`PUT /return/{licenseID}`)
- License must be `active` with `End` in the future
- Device must have previously registered
- Sets `End` = now, status = `returned`
- Creates `EVENT_RETURN`

### Revoke (`PUT /revoke/{licenseID}`)
- Idempotent: no-op if already `revoked`/`cancelled`
- `ready` → `cancelled` (creates `EVENT_CANCEL`)
- Any other status → `revoked` (creates `EVENT_REVOKE`)
- Sets `End` = now; device = "admin"/"system"

## Event Types
`register`, `renew`, `return`, `revoke`, `cancel` — max 500 per license, immutable.

## License Generation Flow

For detailed flow, see [license-generation.md](license-generation.md).

Quick summary:
1. Validate request (`publication_id` or `alt_id`, `user_id`, `text_hint`, `pass_hash`)
2. Look up publication
3. Create `LicenseInfo` (status=`ready`, `MaxEnd` = End + RenewMaxDays)
4. Derive user key: `hex.DecodeString(passhash)` (basic profile)
5. Encrypt content key with user key (AES-256-CBC)
6. Generate key check: encrypt license ID with user key
7. Optionally encrypt user fields (email, name)
8. Sign license with X.509 certificate (RSA-SHA256)
9. Return `.lcpl` JSON

## Key JSON Structures

For complete field-level reference, see [json-structures.md](json-structures.md).

**Content types:**
- License: `application/vnd.readium.lcp.license.v1.0+json`
- Status Doc: `application/vnd.readium.license.status.v1.0+json`

**LCP Profiles:**
- Basic: `http://readium.org/lcp/basic-profile`
- 1.0: `http://readium.org/lcp/profile-1.0`
- 2.x: Wildcard, randomly generates `2.0`–`2.9`

## Status Document Link Rules
- `license` and `register`: always present
- `renew` and `return`: only if `RenewMaxDays` > 0
- `potential_rights.end`: only for `ready`/`active` statuses with `MaxEnd`

## Auto-Expiration
When generating a status doc, if status is `ready`/`active` and `End` < now, status is automatically set to `expired`.
