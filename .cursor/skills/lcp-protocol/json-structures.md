# LCP JSON Structures

## LCP License

```json
{
  "provider": "string (URL)",
  "id": "string (UUID)",
  "issued": "RFC3339 timestamp",
  "updated": "RFC3339 timestamp (optional)",
  "encryption": {
    "profile": "string (URI)",
    "content_key": {
      "algorithm": "http://www.w3.org/2001/04/xmlenc#aes256-cbc",
      "encrypted_value": "base64 bytes"
    },
    "user_key": {
      "algorithm": "http://www.w3.org/2001/04/xmlenc#sha256",
      "text_hint": "string",
      "key_check": "base64 bytes"
    }
  },
  "links": [
    { "rel": "publication", "href": "URL", "type": "MIME", "title": "string", "length": 0, "hash": "string" },
    { "rel": "status", "href": "URL", "type": "application/vnd.readium.license.status.v1.0+json" },
    { "rel": "hint", "href": "URL", "type": "text/html" }
  ],
  "user": {
    "id": "string",
    "email": "string (may be encrypted+base64)",
    "name": "string (may be encrypted+base64)",
    "encrypted": ["email", "name"]
  },
  "rights": {
    "start": "RFC3339 (optional)",
    "end": "RFC3339 (optional)",
    "print": 0,
    "copy": 0
  },
  "signature": {
    "algorithm": "http://www.w3.org/2001/04/xmldsig#rsa-sha256",
    "certificate": "base64 X.509",
    "value": "base64 signature"
  }
}
```

## License Status Document

```json
{
  "id": "string (UUID)",
  "status": "ready|active|expired|returned|revoked|cancelled",
  "message": "string",
  "updated": {
    "license": "RFC3339",
    "status": "RFC3339"
  },
  "links": [
    { "rel": "license", "href": "templated URL", "type": "...", "templated": true },
    { "rel": "register", "href": "templated URL", "type": "...", "templated": true },
    { "rel": "renew", "href": "templated URL", "type": "...", "templated": true },
    { "rel": "return", "href": "templated URL", "type": "...", "templated": true }
  ],
  "potential_rights": {
    "end": "RFC3339 (MaxEnd, only for ready/active)"
  },
  "events": [
    { "timestamp": "RFC3339", "type": "register|renew|return|revoke|cancel", "id": "deviceID", "name": "deviceName" }
  ]
}
```

## License Request (POST /licenses)

```json
{
  "publication_id": "UUID (or use alt_id)",
  "alt_id": "string (alternative to publication_id)",
  "user_id": "string (required)",
  "user_name": "string (optional)",
  "user_email": "string (optional)",
  "user_encrypted": ["email", "name"],
  "text_hint": "string (required)",
  "pass_hash": "hex-encoded SHA-256 (required)",
  "start": "RFC3339 (optional)",
  "end": "RFC3339 (optional)",
  "copy": -1,
  "print": -1,
  "profile": "URI (optional, uses config default)"
}
```
