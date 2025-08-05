# PVPipe Backend GitOps

This repository contains the Kubernetes deployment configurations for the PVPipe backend services using Helm charts and GitOps principles.

## Overview

PVPipe is an enterprise document management and pipeline system with a microservices architecture. This GitOps repository manages the deployment of all backend services.

## Key Features

- **Microservices Architecture**: 12+ specialized services for different functionalities
- **PgBouncer Connection Pooling**: Enabled by default for optimal database performance
- **Flexible Database Access**: Support for read-write and read-only database configurations
- **GitOps Ready**: Designed for FluxCD or ArgoCD deployment automation
- **Security First**: Secrets management, RBAC, and secure configurations

## Services Included

- **Core Services**: Backend API, Authentication, Settings, Email
- **Document Processing**: File management, PDF signing, conversions
- **Search**: Meilisearch integration with dedicated workers
- **Multi-language Support**: Go, Node.js, .NET, and Java services
- **Infrastructure**: Redis, PgBouncer, monitoring tools

## Quick Start

1. **Configure your environment values**:
   ```bash
   cp values.yaml values-production.yaml
   # Edit values-production.yaml with your configuration
   ```

2. **Set required environment variables**:
   ```yaml
   env:
     DATABASE_URL: "postgresql://user:pass@postgres:5432/dbname"
     JWT_SECRET: "your-secret-key"
     # Add other required secrets
   ```

3. **Deploy using Helm**:
   ```bash
   helm install pvpipe ./charts/pvpipe -f values-production.yaml
   ```

## PgBouncer Connection Pooling

PgBouncer is **enabled by default** to provide:
- Reduced database connection overhead
- Better performance under load
- Automatic connection pooling for all services
- Support for both read-write and read-only connections

See [README-pgbouncer.md](charts/pvpipe/README-pgbouncer.md) for detailed configuration.

## Database Access Control

The system supports dual database access modes with automatic routing through PgBouncer:
- Read-Write access for services that need full database access
- Read-Only access for services that only need to query data

See [README-database-access.md](charts/pvpipe/README-database-access.md) for configuration details.

## Documentation

- [PgBouncer Configuration](charts/pvpipe/README-pgbouncer.md)
- [Database Access Control](charts/pvpipe/README-database-access.md)
- [JWT Authentication](charts/pvpipe/README-jwt-authentication.md)

## Requirements

- Kubernetes 1.24+
- Helm 3.10+
- PostgreSQL 13+
- Persistent volume provisioner (for stateful services)

## Security Considerations

- All sensitive data is stored in Kubernetes Secrets
- PgBouncer uses MD5 authentication by default
- Services use JWT for inter-service authentication
- Database credentials are automatically managed and transformed

## Contributing

Please ensure all changes maintain backward compatibility and include appropriate documentation updates.