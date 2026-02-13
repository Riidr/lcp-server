# License Generation — Detailed Flow

## Entry Point
`pkg/api/license_handler.go::GenerateLicense()`

## Step-by-Step

### 1. Request Validation
- Bind `LicenseRequest` payload
- Require `publication_id` OR `alt_id`
- Require `user_id`, `text_hint`, `pass_hash`

### 2. Publication Lookup
- Fetch by UUID or AltID
- Verify exists and not soft-deleted

### 3. Create LicenseInfo (`newLicenseInfo()`)
- Generate new UUID
- Set `Provider` from config, `Status` = `ready`
- Set `UserID`, `PublicationID`, `Start`, `End` from request
- `Copy`/`Print` default to -1 (unlimited)
- `MaxEnd` = `End + RenewMaxDays` (if End exists and RenewMaxDays > 0)

### 4. Build Encryption (`setEncryption()`)
- Validate profile (supports "2.x" wildcard → random "2.0"–"2.9")
- **User key**: `hex.DecodeString(passhash)` → 32-byte AES key (basic profile)
- **Content key encryption**: AES-256-CBC encrypt `pub.EncryptionKey` with user key
- **Key check**: AES-256-CBC encrypt `licenseID` with user key

### 5. Set Links (`setLinks()`)
- `publication`: href, type, title, size, checksum from publication
- `status`: `{publicBaseUrl}/status/{licenseID}`
- `hint`: expanded template from config

### 6. Set User (`setUser()`)
- For each field in `User.Encrypted` list: AES-CBC encrypt with user key, base64 encode
- Fields: `id`, `email`, `name` (only those listed in `encrypted` array)

### 7. Set Rights (`setRights()`)
- `Start`, `End` from LicenseInfo
- `Print`, `Copy` omitted if -1 (unlimited)

### 8. Sign (`setSignature()`)
- Remove existing signature, sign with X.509 certificate (RSA-SHA256), restore

### 9. Return
- If `?link=true`: HTTP 303 redirect to fresh license link
- Otherwise: JSON license document

## AES-CBC Details
- Key: 256 bits (32 bytes)
- Block: 128 bits (16 bytes)
- IV: Random 16 bytes prepended to ciphertext
- Padding: W3C scheme
- Algorithm URI: `http://www.w3.org/2001/04/xmlenc#aes256-cbc`
