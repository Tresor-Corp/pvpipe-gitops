# PgBouncer Connection Pooling Configuration

This document explains how PgBouncer is configured as a connection pooler for all microservices in the PVPipe deployment.

## Overview

PgBouncer acts as a lightweight connection pooler between the microservices and PostgreSQL database. **PgBouncer is enabled by default** to provide better performance and resource efficiency. All database connections from the microservices go through PgBouncer, which maintains a pool of connections to the actual PostgreSQL server.

## Architecture

```
Microservices → PgBouncer → PostgreSQL
```

## How It Works

1. **Automatic URL Transformation**: When PgBouncer is enabled (`pgbouncer.enabled: true`), the DATABASE_URL environment variable is automatically transformed for all services to point to PgBouncer instead of directly to PostgreSQL.

2. **Original URL Preservation**: The original DATABASE_URL is preserved as DATABASE_URL_ORIGINAL for PgBouncer to use when connecting to the actual PostgreSQL server.

3. **Dynamic Configuration**: PgBouncer configuration is generated dynamically at startup from the DATABASE_URL, extracting host, port, username, password, and database name.

## Configuration

### Default Configuration

PgBouncer is **enabled by default** with the following configuration:

```yaml
pgbouncer:
  enabled: true  # Enabled by default
  replicas: 1
  config:
    poolMode: transaction
    defaultPoolSize: 25
    maxClientConn: 100
    maxDbConnections: 50
```

### Disable PgBouncer

If you need to disable PgBouncer (not recommended for production):

```yaml
pgbouncer:
  enabled: false
```

### Pool Modes

- **transaction** (default): Pool connections at transaction level. Recommended for most applications.
- **session**: Pool connections at session level. Use if your app relies on session-level features.
- **statement**: Pool connections at statement level. Most aggressive pooling.

### Connection Limits

- `defaultPoolSize`: Number of server connections per database/user pair (default: 25)
- `maxClientConn`: Maximum number of client connections (default: 100)
- `maxDbConnections`: Maximum number of connections to PostgreSQL (default: 50)

## Benefits

1. **Connection Pooling**: Reduces the number of connections to PostgreSQL
2. **Better Performance**: Reuses existing connections, reducing connection overhead
3. **Resource Efficiency**: Prevents connection exhaustion on the database
4. **Transparent**: No application code changes required
5. **Centralized Management**: Single point for database connection configuration

## Monitoring

Connect to PgBouncer admin console:

```bash
kubectl exec -it <pgbouncer-pod> -- psql -h localhost -p 5432 -U pgbouncer pgbouncer
```

Useful commands:
- `SHOW POOLS;` - Show connection pool statistics
- `SHOW CLIENTS;` - Show client connections
- `SHOW SERVERS;` - Show server connections
- `SHOW STATS;` - Show general statistics

## Troubleshooting

1. **Connection Refused**: Check if PgBouncer pod is running
2. **Authentication Failed**: Verify DATABASE_URL is correctly set in values
3. **Pool Exhausted**: Increase `defaultPoolSize` or `maxDbConnections`
4. **Transaction Mode Issues**: Switch to `session` mode if needed

## Security

- PgBouncer uses MD5 authentication by default
- Admin user is created with a default password (should be changed in production)
- All database credentials are stored in Kubernetes secrets