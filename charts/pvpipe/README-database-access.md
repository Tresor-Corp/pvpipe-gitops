# Database Access Control for Microservices

This document explains how to configure read-only database access for specific microservices in the PVPipe deployment.

## Overview

The PVPipe deployment supports dual database access modes:
- **Read-Write Access**: Full database access (default)
- **Read-Only Access**: Restricted to SELECT queries only

## Configuration

### 1. Database URLs

In your `values.yaml` or environment-specific values file, configure both database URLs:

```yaml
env:
  # Standard database URL with full read-write access
  DATABASE_URL: "postgresql://pvpipe_user:password@postgres:5432/pvpipe_db"
  
  # Read-only database URL (use a database user with only SELECT privileges)
  DATABASE_URL_READONLY: "postgresql://pvpipe_readonly:password@postgres:5432/pvpipe_db"
```

### 2. Service Configuration

Each microservice can be configured to use either read-write or read-only database access:

```yaml
# Command Center Service
commandCenter:
  enabled: true
  useReadOnlyDatabase: false  # Keep false if write access is needed
```

### 3. Database User Setup

Before deploying, create a read-only database user in PostgreSQL:

```sql
-- Create read-only user
CREATE USER pvpipe_readonly WITH PASSWORD 'your_secure_password';

-- Grant connect privilege
GRANT CONNECT ON DATABASE pvpipe_db TO pvpipe_readonly;

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO pvpipe_readonly;

-- Grant SELECT on all tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO pvpipe_readonly;

-- Grant SELECT on future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO pvpipe_readonly;
```

## How It Works

1. Both `DATABASE_URL` and `DATABASE_URL_READONLY` are stored in the Kubernetes Secret
2. When `useReadOnlyDatabase: true` is set for a service, the deployment overrides the `DATABASE_URL` environment variable with the value from `DATABASE_URL_READONLY`
3. The application code continues to use `DATABASE_URL` as normal, but connects with read-only privileges

## Benefits

- **Security**: Follows the principle of least privilege
- **No Code Changes**: Applications don't need modification
- **Flexible**: Easy to switch services between access modes
- **Centralized**: All configuration in Helm values

## Example Use Cases

- **command-center**: Audit service that might only need to read data (configurable)
- **backend**: Main application that needs full database access (read-write)