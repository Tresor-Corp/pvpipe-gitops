# JWT Authentication Configuration

This guide explains how to configure JWT authentication in the PVPipe deployment, including support for multiple token sources to handle different authentication scenarios.

## Overview

The Traefik JWT middleware validates JWT tokens before routing requests to backend services. It supports reading tokens from multiple sources, making it flexible for various client types (browsers, APIs, mobile apps).

## Token Sources

The JWT middleware is configured to check for tokens in the following order:

1. **Authorization Header (Bearer Token)** - Standard for API requests
   - Header: `Authorization: Bearer <token>`
   - Best for: REST APIs, mobile apps, server-to-server communication

2. **Cookie** - Secure for browser-based applications
   - Cookie: `jwt_token=<token>`
   - Best for: Web applications, file downloads, browser navigation
   - Benefits: Works with direct browser navigation, can use httpOnly flag

3. **Custom Header** - Alternative for special cases
   - Header: `X-Auth-Token: <token>`
   - Best for: Legacy systems, special API requirements

## Configuration

### Enable JWT Authentication

In your `values.yaml`:

```yaml
traefik:
  middleware:
    jwt:
      enabled: true  # Enable JWT validation
      
      # JWT signing configuration
      secret:
        value: "your-secret-key"  # Or use existingSecret
      algorithm: "HS256"
      
      # Token sources (checked in order)
      sources:
        - type: bearer
          key: Authorization
        - type: cookie
          key: jwt_token
        - type: header
          key: X-Auth-Token
      
      # Required claims in the JWT payload
      requiredClaims:
        - exp  # Expiration time
        - iat  # Issued at time
        - sub  # Subject (user ID)
      
      # Forward JWT claims as headers to backend
      forwardHeaders:
        - claim: sub
          header: X-User-Id
        - claim: email
          header: X-User-Email
```

### Protect Specific Routes

Configure which routes require JWT authentication:

```yaml
traefik:
  routes:
    api:
      enabled: true
      pathPrefix: "/api"
      protected: true  # Requires JWT
      service: "{{ .Release.Name }}-api"
      port: 80
    
    public:
      enabled: true
      pathPrefix: "/public"
      protected: false  # No JWT required
      service: "{{ .Release.Name }}-public"
      port: 80
```

## Security Best Practices

### Avoid Query String Tokens

**Never pass JWT tokens as query parameters** (e.g., `?access_code=<token>`):
- ❌ Appears in server logs and browser history
- ❌ Can leak through Referer headers
- ❌ Visible in URLs and easily shared accidentally

### Recommended Patterns for File Downloads

1. **Cookie-Based Authentication**
   ```javascript
   // Set secure cookie after login
   document.cookie = `jwt_token=${token}; Secure; HttpOnly; SameSite=Strict`;
   
   // Direct browser navigation works
   window.location.href = '/api/files/download/123';
   ```

2. **Two-Step Download Process**
   ```javascript
   // 1. Request download URL with JWT in header
   const response = await fetch('/api/files/request-download/123', {
     headers: { 'Authorization': `Bearer ${token}` }
   });
   
   // 2. Get temporary signed URL
   const { downloadUrl } = await response.json();
   
   // 3. Navigate to signed URL (no auth needed)
   window.location.href = downloadUrl;
   ```

3. **Form-Based Download**
   ```html
   <form method="POST" action="/api/files/download">
     <input type="hidden" name="fileId" value="123">
     <button>Download</button>
   </form>
   <!-- JWT sent via cookie -->
   ```

## JWT Payload Structure

Example JWT payload that meets the requirements:

```json
{
  "sub": "user123",              // User ID (required)
  "email": "user@example.com",   // User email
  "role": "admin",               // User role
  "exp": 1704067200,             // Expiration (required)
  "iat": 1704063600,             // Issued at (required)
  "iss": "pvpipe-auth",          // Issuer (optional)
  "aud": "pvpipe-api"            // Audience (optional)
}
```

## Troubleshooting

### Token Not Found
- Check token is sent in one of the configured sources
- Verify cookie name matches configuration
- Ensure Authorization header format is correct: `Bearer <token>`

### Token Validation Failed
- Verify token signature with correct secret
- Check required claims are present (exp, iat, sub)
- Ensure token hasn't expired

### 304 Redirects and File Routes
The JWT middleware validates tokens before your application responds, so it works with:
- ✅ All HTTP response codes (200, 304, 302, etc.)
- ✅ File downloads and streaming
- ✅ View routes and redirects

## Migration from Query String Tokens

If currently using query string tokens (`?access_code=<token>`):

1. Update clients to send tokens via:
   - Authorization header for APIs
   - Secure cookies for browser apps

2. Configure middleware with both old and new sources during transition:
   ```yaml
   sources:
     - type: bearer
       key: Authorization
     - type: cookie
       key: jwt_token
     - type: query        # Temporary during migration
       key: access_code   # Remove after migration
   ```

3. Monitor logs and remove query source after migration complete