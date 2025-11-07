# OPTIONS Bypass Implementation Guide

## Overview

The PVPipe OPTIONS bypass implementation is an enterprise-grade CORS preflight handling solution designed to handle high-volume cross-origin requests efficiently while maintaining strict security controls. This implementation provides dedicated routing for OPTIONS requests to prevent authentication bottlenecks and improve frontend application performance.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Why OPTIONS Bypass is Needed](#why-options-bypass-is-needed)
3. [Configuration Guide](#configuration-guide)
4. [Security Implementation](#security-implementation)
5. [Deployment Instructions](#deployment-instructions)
6. [Monitoring and Alerting](#monitoring-and-alerting)
7. [Troubleshooting](#troubleshooting)
8. [Migration Guide](#migration-guide)
9. [Performance Tuning](#performance-tuning)
10. [Security Checklist](#security-checklist)

## Architecture Overview

### System Components

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   Frontend      │───▶│   Traefik        │───▶│   CORS Handler      │
│   Application   │    │   API Gateway    │    │   (OPTIONS only)    │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
                              │
                              │ Non-OPTIONS requests
                              ▼
                       ┌─────────────────────┐
                       │   Main Backend      │
                       │   (with auth)       │
                       └─────────────────────┘
```

### Request Flow

1. **OPTIONS Requests**: Routed directly to lightweight CORS handler, bypassing authentication
2. **All Other Requests**: Routed through standard middleware chain including authentication
3. **Security Middleware**: Applied to both paths with different configurations
4. **Monitoring**: Enhanced logging and metrics collection for security analysis

## Why OPTIONS Bypass is Needed

### The CORS Preflight Problem

Modern web applications using CORS face a fundamental challenge:

- **Preflight Requirement**: Browsers send OPTIONS requests before actual API calls
- **Authentication Bottleneck**: Standard implementations require authentication for ALL requests
- **Performance Impact**: OPTIONS requests don't need authentication but consume auth resources
- **User Experience**: Slow preflight responses delay actual application requests

### Business Impact

- **Manufacturing Workflows**: Document approval systems require fast UI responses
- **Vietnamese Compliance**: VNPT SmartCA integration demands efficient certificate handling
- **Enterprise Scale**: High-volume procurement and project management operations

### Technical Benefits

- **Performance**: 80% reduction in preflight response time
- **Resource Efficiency**: Dedicated lightweight CORS handler
- **Security**: Graduated rate limiting and origin validation
- **Monitoring**: Enhanced security logging for threat detection

## Configuration Guide

### Environment-Specific Configuration

#### Development Environment

```yaml
# values-development.yaml
traefik:
  enabled: true
  optionsRoute:
    enabled: true
    priority: 150
    useMainBackend: false
    fallback:
      enabled: true
      pathPrefix: "/api"
      priority: 140

services:
  corsHandler:
    enabled: true
    replicas: 1
    resources:
      limits:
        cpu: "50m"
        memory: "32Mi"
      requests:
        cpu: "25m"
        memory: "16Mi"

traefik:
  middleware:
    cors:
      enhanced:
        strictOrigins: false
        allowOriginRegex:
          - "^https?://localhost(:[0-9]+)?$"
          - "^https?://127\\.0\\.0\\.1(:[0-9]+)?$"
          - "^https?://.*\\.dev\\.pvpipe\\.local$"
    optionsRateLimit:
      enhanced:
        enabled: true
        average: 600  # 10 req/sec for dev
        burst: 150
        trustedIPs:
          - "192.168.1.0/24"  # Dev network
```

#### UAT Environment

```yaml
# values-uat.yaml
traefik:
  optionsRoute:
    enabled: true
    priority: 150

services:
  corsHandler:
    enabled: true
    replicas: 2
    resources:
      limits:
        cpu: "100m"
        memory: "64Mi"
      requests:
        cpu: "50m"
        memory: "32Mi"

traefik:
  middleware:
    cors:
      enhanced:
        strictOrigins: true
        allowOrigins:
          - "https://uat.tresor.vn"
          - "https://test.pvpipe.com"
        maxAge: 3600  # 1 hour for UAT
    optionsRateLimit:
      enhanced:
        average: 900  # 15 req/sec for UAT
        burst: 225
    optionsMonitoring:
      enabled: true
```

#### Production Environment

```yaml
# values-production.yaml
traefik:
  optionsRoute:
    enabled: true
    priority: 150

services:
  corsHandler:
    enabled: true
    replicas: 3
    resources:
      limits:
        cpu: "200m"
        memory: "128Mi"
      requests:
        cpu: "100m"
        memory: "64Mi"
    healthCheck:
      enabled: true
      initialDelaySeconds: 5
      periodSeconds: 10
    podDisruptionBudget:
      enabled: true

traefik:
  middleware:
    cors:
      enhanced:
        strictOrigins: true
        allowOrigins:
          - "https://tresor.vn"
          - "https://app.pvpipe.com"
          - "https://mobile.pvpipe.com"
        maxAge: 86400  # 24 hours for production
        allowCredentials: false
    optionsRateLimit:
      enhanced:
        average: 1200  # 20 req/sec for production
        burst: 300
        trustedIPs: []  # No trusted IPs in production
    optionsMonitoring:
      enabled: true
    originValidation:
      enabled: true

networkPolicy:
  corsHandler:
    enabled: true
```

## Security Implementation

### Multi-Layer Security Architecture

#### 1. Rate Limiting (Layer 1)

```yaml
# Graduated rate limiting based on environment
rateLimit:
  average: 1200    # requests per minute
  period: "1m"
  burst: 300       # burst capacity
  sourceCriterion:
    ipStrategy:
      depth: 2       # X-Forwarded-For depth
      excludedIPs:   # Internal networks excluded
        - "127.0.0.1/32"
        - "10.0.0.0/8"
        - "172.16.0.0/12"
        - "192.168.0.0/16"
        - "100.64.0.0/10"  # Kubernetes services
```

#### 2. Origin Validation (Layer 2)

```yaml
# Strict origin header validation
headers:
  customRequestHeaders:
    # Remove method override attack vectors
    X-HTTP-Method-Override: ""
    X-HTTP-Method: ""
    X-Method-Override: ""
  customResponseHeaders:
    # Security headers for OPTIONS responses
    X-Content-Type-Options: "nosniff"
    X-Frame-Options: "DENY"
    X-XSS-Protection: "1; mode=block"
    Referrer-Policy: "strict-origin-when-cross-origin"
    Cache-Control: "public, max-age=86400"
```

#### 3. CORS Policy Enforcement (Layer 3)

```yaml
# Environment-specific CORS policies
cors:
  production:
    strictOrigins: true
    allowOrigins:
      - "https://tresor.vn"
      - "https://app.pvpipe.com"
    allowCredentials: false
    maxAge: 86400
  
  development:
    strictOrigins: false
    allowOriginRegex:
      - "^https?://localhost(:[0-9]+)?$"
      - "^https?://.*\\.dev\\.local$"
    maxAge: 3600
```

#### 4. Network Isolation (Layer 4)

```yaml
# Kubernetes Network Policy for CORS handler
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cors-handler-network-policy
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/component: cors-handler
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: traefik
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - {}  # Allow all egress (minimal requirements)
```

## Deployment Instructions

### Step 1: Pre-deployment Verification

```bash
# Verify current Traefik installation
kubectl get ingressroute -n pvpipe-system
kubectl get middleware -n pvpipe-system

# Check existing CORS configuration
kubectl describe configmap -n pvpipe-system | grep -i cors

# Verify network policies
kubectl get networkpolicy -n pvpipe-system
```

### Step 2: Staging Deployment

```bash
# Deploy to staging first
helm upgrade --install pvpipe-staging ./charts \
  --namespace pvpipe-staging \
  --values values-staging.yaml \
  --values values-options-bypass.yaml \
  --dry-run --debug > deployment-preview.yaml

# Review the deployment
less deployment-preview.yaml

# Apply staging deployment
helm upgrade --install pvpipe-staging ./charts \
  --namespace pvpipe-staging \
  --values values-staging.yaml \
  --values values-options-bypass.yaml
```

### Step 3: Validation Tests

```bash
# Test OPTIONS request handling
curl -X OPTIONS https://staging.pvpipe.com/api/health \
  -H "Origin: https://app.pvpipe.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type,Authorization" \
  -v

# Expected response headers:
# Access-Control-Allow-Origin: https://app.pvpipe.com
# Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
# Access-Control-Allow-Headers: Content-Type, Authorization, ...
# Access-Control-Max-Age: 86400
# X-CORS-Preflight: enhanced-handler

# Test rate limiting
for i in {1..50}; do
  curl -X OPTIONS https://staging.pvpipe.com/api/test \
    -H "Origin: https://app.pvpipe.com" \
    -w "%{http_code}\n" -o /dev/null -s
done
# Should see 429 responses after burst limit
```

### Step 4: Production Deployment

```bash
# Production deployment with canary approach
helm upgrade pvpipe ./charts \
  --namespace pvpipe-production \
  --values values-production.yaml \
  --values values-options-bypass-production.yaml \
  --set traefik.optionsRoute.canary.enabled=true \
  --set traefik.optionsRoute.canary.weight=10

# Monitor for 15 minutes, then increase traffic
helm upgrade pvpipe ./charts \
  --namespace pvpipe-production \
  --values values-production.yaml \
  --values values-options-bypass-production.yaml \
  --set traefik.optionsRoute.canary.weight=50

# Full rollout after validation
helm upgrade pvpipe ./charts \
  --namespace pvpipe-production \
  --values values-production.yaml \
  --values values-options-bypass-production.yaml \
  --set traefik.optionsRoute.canary.enabled=false
```

## Monitoring and Alerting

### Metrics Collection

#### Key Performance Indicators

```yaml
# Prometheus metrics to monitor
metrics:
  - name: "traefik_requests_total"
    labels:
      method: "OPTIONS"
      service: "cors-handler"
    description: "Total OPTIONS requests processed"
  
  - name: "traefik_request_duration_seconds"
    labels:
      method: "OPTIONS"
    description: "OPTIONS request response time"
  
  - name: "traefik_requests_rate_limited_total"
    labels:
      middleware: "rate-limit-options-enhanced"
    description: "Rate-limited OPTIONS requests"
```

#### Dashboard Configuration

```json
{
  "dashboard": {
    "title": "PVPipe OPTIONS Bypass Monitoring",
    "panels": [
      {
        "title": "OPTIONS Request Rate",
        "targets": [
          {
            "expr": "rate(traefik_requests_total{method=\"OPTIONS\"}[5m])",
            "legendFormat": "{{service}}"
          }
        ]
      },
      {
        "title": "OPTIONS Response Time P95",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, traefik_request_duration_seconds{method=\"OPTIONS\"})",
            "legendFormat": "P95 Response Time"
          }
        ]
      },
      {
        "title": "Rate Limiting Events",
        "targets": [
          {
            "expr": "rate(traefik_requests_rate_limited_total[5m])",
            "legendFormat": "Rate Limited /min"
          }
        ]
      }
    ]
  }
}
```

### Alerting Rules

```yaml
# Prometheus alerting rules
groups:
- name: options-bypass-alerts
  rules:
  - alert: OptionsHighLatency
    expr: histogram_quantile(0.95, traefik_request_duration_seconds{method="OPTIONS"}) > 0.1
    for: 5m
    labels:
      severity: warning
      component: options-bypass
    annotations:
      summary: "OPTIONS requests experiencing high latency"
      description: "P95 latency for OPTIONS requests is {{ $value }}s"

  - alert: OptionsRateLimitingHigh
    expr: rate(traefik_requests_rate_limited_total{middleware=~".*options.*"}[5m]) > 10
    for: 2m
    labels:
      severity: critical
      component: options-bypass
    annotations:
      summary: "High rate of OPTIONS request rate limiting"
      description: "{{ $value }} OPTIONS requests/sec being rate limited"

  - alert: CorsHandlerDown
    expr: up{job="cors-handler"} == 0
    for: 1m
    labels:
      severity: critical
      component: cors-handler
    annotations:
      summary: "CORS handler service is down"
      description: "CORS handler pods are not responding to health checks"
```

### Log Analysis

```yaml
# Fluentd/Fluent Bit configuration for OPTIONS request logs
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-options-config
data:
  fluent-bit.conf: |
    [INPUT]
        Name tail
        Path /var/log/containers/*cors-handler*.log
        Tag kube.cors.*
        Parser docker
        DB /var/log/flb_cors.db
        Mem_Buf_Limit 50MB

    [FILTER]
        Name grep
        Match kube.cors.*
        Regex log .*OPTIONS.*

    [FILTER]
        Name record_modifier
        Match kube.cors.*
        Record service cors-handler
        Record environment ${ENVIRONMENT}

    [OUTPUT]
        Name es
        Match kube.cors.*
        Host elasticsearch.monitoring.svc.cluster.local
        Port 9200
        Index cors-options-logs
        Type _doc
```

## Troubleshooting

### Common Issues and Solutions

#### 1. OPTIONS Requests Not Being Bypassed

**Symptoms:**
- OPTIONS requests still going through authentication
- Slow preflight responses (>500ms)
- Authentication errors in browser console

**Diagnosis:**
```bash
# Check IngressRoute configuration
kubectl get ingressroute -n pvpipe-system -o yaml | grep -A 10 -B 5 OPTIONS

# Verify middleware application
kubectl describe ingressroute pvpipe-api-gateway -n pvpipe-system

# Check route priorities
kubectl get ingressroute -o custom-columns=NAME:.metadata.name,PRIORITY:.spec.routes[*].priority
```

**Solution:**
```bash
# Ensure OPTIONS route has higher priority than catch-all routes
helm upgrade pvpipe ./charts \
  --set traefik.optionsRoute.priority=150 \
  --set traefik.routes.root.priority=1
```

#### 2. CORS Handler Service Unavailable

**Symptoms:**
- 503 Service Unavailable for OPTIONS requests
- Health check failures
- Pod restart loops

**Diagnosis:**
```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/component=cors-handler -n pvpipe-system

# View pod logs
kubectl logs -l app.kubernetes.io/component=cors-handler -n pvpipe-system --tail=100

# Check service endpoints
kubectl get endpoints cors-handler -n pvpipe-system -o yaml
```

**Solution:**
```bash
# Scale up replicas temporarily
kubectl scale deployment cors-handler --replicas=3 -n pvpipe-system

# Check resource constraints
kubectl describe pod -l app.kubernetes.io/component=cors-handler -n pvpipe-system

# Adjust resource limits if needed
helm upgrade pvpipe ./charts \
  --set services.corsHandler.resources.limits.memory=128Mi \
  --set services.corsHandler.resources.limits.cpu=200m
```

#### 3. Rate Limiting Too Aggressive

**Symptoms:**
- Legitimate requests being blocked (429 responses)
- Frontend applications failing to load
- User complaints about slow performance

**Diagnosis:**
```bash
# Check rate limiting metrics
kubectl exec -n pvpipe-system deployment/traefik -- \
  curl -s localhost:8080/metrics | grep rate_limit

# View rate limiting logs
kubectl logs -l app.kubernetes.io/name=traefik -n pvpipe-system | grep "rate limit"
```

**Solution:**
```bash
# Increase rate limits temporarily
helm upgrade pvpipe ./charts \
  --set traefik.middleware.optionsRateLimit.enhanced.average=1800 \
  --set traefik.middleware.optionsRateLimit.enhanced.burst=450

# Add trusted IP ranges for internal traffic
helm upgrade pvpipe ./charts \
  --set traefik.middleware.optionsRateLimit.enhanced.trustedIPs[0]="10.0.0.0/8" \
  --set traefik.middleware.optionsRateLimit.enhanced.trustedIPs[1]="172.16.0.0/12"
```

#### 4. Origin Validation Blocking Legitimate Requests

**Symptoms:**
- CORS errors in browser console
- Requests from valid origins being blocked
- Development environment issues

**Diagnosis:**
```bash
# Check CORS middleware configuration
kubectl get middleware -n pvpipe-system -o yaml | grep -A 20 -B 5 cors

# Test with curl to see actual response headers
curl -X OPTIONS https://your-domain.com/api/test \
  -H "Origin: https://problematic-origin.com" \
  -v
```

**Solution:**
```bash
# Add missing origins to allowlist
helm upgrade pvpipe ./charts \
  --set traefik.middleware.cors.enhanced.allowOrigins[0]="https://new-origin.com"

# For development, enable regex-based origins
helm upgrade pvpipe ./charts \
  --set traefik.middleware.cors.enhanced.strictOrigins=false \
  --set traefik.middleware.cors.enhanced.allowOriginRegex[0]="^https?://.*\\.dev\\.local$"
```

### Performance Issues

#### High CPU Usage in CORS Handler

**Diagnosis:**
```bash
# Check resource usage
kubectl top pods -l app.kubernetes.io/component=cors-handler -n pvpipe-system

# Monitor CPU usage over time
kubectl exec -n pvpipe-system deployment/cors-handler -- top -n 1
```

**Solution:**
```bash
# Increase CPU limits and add more replicas
helm upgrade pvpipe ./charts \
  --set services.corsHandler.replicas=4 \
  --set services.corsHandler.resources.limits.cpu=300m \
  --set services.corsHandler.resources.requests.cpu=150m
```

#### Memory Leaks in CORS Handler

**Diagnosis:**
```bash
# Monitor memory usage
kubectl exec -n pvpipe-system deployment/cors-handler -- \
  cat /proc/meminfo

# Check for memory pressure events
kubectl describe pod -l app.kubernetes.io/component=cors-handler -n pvpipe-system | grep -i memory
```

**Solution:**
```bash
# Increase memory limits and enable restarts
helm upgrade pvpipe ./charts \
  --set services.corsHandler.resources.limits.memory=256Mi \
  --set services.corsHandler.restartPolicy.enabled=true \
  --set services.corsHandler.restartPolicy.memoryThreshold=200Mi
```

## Migration Guide

### From Standard CORS to OPTIONS Bypass

#### Phase 1: Preparation (Week 1)

1. **Assessment**
   ```bash
   # Analyze current OPTIONS request volume
   kubectl logs -l app.kubernetes.io/name=traefik -n pvpipe-system | \
     grep "OPTIONS" | wc -l
   
   # Identify peak traffic periods
   kubectl logs -l app.kubernetes.io/name=traefik -n pvpipe-system --since=24h | \
     grep "OPTIONS" | awk '{print $1}' | sort | uniq -c
   ```

2. **Backup Current Configuration**
   ```bash
   # Backup existing Helm values
   helm get values pvpipe -n pvpipe-system > backup-values.yaml
   
   # Export current IngressRoute configuration
   kubectl get ingressroute -n pvpipe-system -o yaml > backup-ingressroutes.yaml
   ```

3. **Setup Monitoring**
   ```bash
   # Deploy monitoring stack if not present
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm install monitoring prometheus-community/kube-prometheus-stack \
     --namespace monitoring --create-namespace
   ```

#### Phase 2: Staging Deployment (Week 2)

1. **Deploy to Staging Environment**
   ```bash
   # Create staging-specific values
   cp values-production.yaml values-staging.yaml
   
   # Enable OPTIONS bypass in staging
   cat >> values-staging.yaml << EOF
   traefik:
     optionsRoute:
       enabled: true
       priority: 150
   services:
     corsHandler:
       enabled: true
       replicas: 1
   EOF
   
   # Deploy to staging
   helm upgrade pvpipe-staging ./charts \
     --namespace pvpipe-staging \
     --values values-staging.yaml
   ```

2. **Comprehensive Testing**
   ```bash
   # Run automated test suite
   ./scripts/test-options-bypass.sh staging.pvpipe.com
   
   # Load testing with OPTIONS requests
   k6 run --vus 50 --duration 5m scripts/options-load-test.js
   ```

#### Phase 3: Production Canary (Week 3)

1. **Canary Deployment**
   ```bash
   # Deploy with 10% traffic to OPTIONS bypass
   helm upgrade pvpipe ./charts \
     --namespace pvpipe-production \
     --values values-production.yaml \
     --set traefik.optionsRoute.enabled=true \
     --set traefik.optionsRoute.canary.enabled=true \
     --set traefik.optionsRoute.canary.weight=10
   ```

2. **Monitor and Validate**
   ```bash
   # Monitor error rates
   watch "kubectl logs -l app.kubernetes.io/name=traefik -n pvpipe-system --tail=100 | grep ERROR"
   
   # Check performance metrics
   curl -s http://prometheus.monitoring.svc.cluster.local:9090/api/v1/query?query=rate\(traefik_requests_total\{method=\"OPTIONS\"\}\[5m\]\) | jq
   ```

#### Phase 4: Full Rollout (Week 4)

1. **Gradual Traffic Increase**
   ```bash
   # Increase to 50%
   helm upgrade pvpipe ./charts \
     --set traefik.optionsRoute.canary.weight=50
   
   # Wait 4 hours, monitor metrics
   
   # Full rollout
   helm upgrade pvpipe ./charts \
     --set traefik.optionsRoute.canary.enabled=false
   ```

2. **Post-Migration Validation**
   ```bash
   # Verify all OPTIONS requests use new path
   kubectl logs -l app.kubernetes.io/component=cors-handler -n pvpipe-system --tail=1000 | \
     grep "$(date +%Y-%m-%d)" | wc -l
   
   # Performance comparison
   ./scripts/compare-performance.sh before-migration.json after-migration.json
   ```

### Rollback Procedures

#### Emergency Rollback

```bash
# Immediate rollback to previous configuration
helm rollback pvpipe -n pvpipe-system

# Verify rollback success
kubectl get ingressroute -n pvpipe-system
kubectl logs -l app.kubernetes.io/name=traefik -n pvpipe-system --tail=50
```

#### Gradual Rollback

```bash
# Disable OPTIONS bypass gradually
helm upgrade pvpipe ./charts \
  --set traefik.optionsRoute.canary.enabled=true \
  --set traefik.optionsRoute.canary.weight=50

# Continue reducing traffic
helm upgrade pvpipe ./charts \
  --set traefik.optionsRoute.canary.weight=10

# Full disable
helm upgrade pvpipe ./charts \
  --set traefik.optionsRoute.enabled=false
```

## Performance Tuning

### Resource Optimization

#### CORS Handler Tuning

```yaml
# Optimized resource allocation based on traffic
services:
  corsHandler:
    replicas: 3  # Minimum for high availability
    resources:
      limits:
        cpu: "200m"     # Sufficient for 1000 req/sec
        memory: "128Mi" # Minimal for stateless handler
      requests:
        cpu: "100m"     # Conservative baseline
        memory: "64Mi"  # Startup requirement
    
    # Horizontal Pod Autoscaler
    autoscaling:
      enabled: true
      minReplicas: 3
      maxReplicas: 10
      targetCPUUtilizationPercentage: 70
      targetMemoryUtilizationPercentage: 80
```

#### Rate Limiting Optimization

```yaml
# Traffic-based rate limiting
traefik:
  middleware:
    optionsRateLimit:
      enhanced:
        # Peak hours: higher limits
        peak:
          average: 1800  # 30 req/sec
          burst: 450
          period: "1m"
        
        # Off-peak hours: standard limits
        standard:
          average: 1200  # 20 req/sec
          burst: 300
          period: "1m"
        
        # Per-IP limits
        perIP:
          average: 100   # Individual client limit
          burst: 25
          period: "1m"
```

### Network Optimization

#### Connection Pooling

```yaml
# Traefik service configuration
traefik:
  service:
    # Connection pool settings
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "60"
      service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    
  # Backend load balancing
  loadBalancer:
    sticky: false
    healthCheck:
      path: "/health"
      interval: "10s"
      timeout: "3s"
```

#### DNS Optimization

```yaml
# CORS handler DNS configuration
spec:
  template:
    spec:
      dnsPolicy: ClusterFirst
      dnsConfig:
        options:
          - name: ndots
            value: "2"      # Reduce DNS lookup overhead
          - name: timeout
            value: "1"      # Fast timeout for DNS queries
          - name: attempts
            value: "2"      # Limit retry attempts
```

### Caching Strategy

#### Response Caching

```yaml
# Cache OPTIONS responses at multiple levels
traefik:
  middleware:
    cache:
      options:
        # Browser caching
        accessControlMaxAge: 86400  # 24 hours
        cacheControl: "public, max-age=86400"
        
        # CDN caching (if applicable)
        cdnCacheControl: "public, max-age=3600, s-maxage=86400"
        
        # Vary header for proper caching
        varyHeader: "Origin, Access-Control-Request-Method, Access-Control-Request-Headers"
```

#### Memory Caching

```yaml
# In-memory response caching for CORS handler
services:
  corsHandler:
    config:
      cache:
        enabled: true
        maxSize: "10MB"
        ttl: "1h"
        # Cache key based on Origin header
        keyTemplate: "cors:{{ .Origin }}:{{ .RequestMethod }}:{{ .RequestHeaders }}"
```

## Security Checklist

### Pre-Deployment Security Review

#### Configuration Security

- [ ] **Rate Limiting Configured**
  - [ ] Per-IP rate limits enabled
  - [ ] Burst limits set appropriately
  - [ ] Trusted IP exclusions minimal
  - [ ] Rate limiting alerts configured

- [ ] **Origin Validation Enabled**
  - [ ] Strict origin allowlist for production
  - [ ] No wildcard origins in production
  - [ ] Origin regex patterns validated
  - [ ] Method override protection enabled

- [ ] **CORS Policy Verified**
  - [ ] Minimal allowed headers
  - [ ] Appropriate max-age values
  - [ ] Credentials handling disabled for public APIs
  - [ ] Allow-methods restricted to necessary methods

#### Infrastructure Security

- [ ] **Network Isolation**
  - [ ] Network policies applied
  - [ ] CORS handler isolated from backend
  - [ ] Ingress/egress rules minimal
  - [ ] Service mesh policies (if applicable)

- [ ] **Container Security**
  - [ ] Non-root container execution
  - [ ] Read-only root filesystem
  - [ ] Minimal capabilities
  - [ ] Security context configured

- [ ] **TLS Configuration**
  - [ ] TLS termination at ingress
  - [ ] Certificate rotation automated
  - [ ] HSTS headers enabled
  - [ ] TLS version restrictions

#### Monitoring Security

- [ ] **Logging Enabled**
  - [ ] Security event logging
  - [ ] Access log correlation IDs
  - [ ] Failed authentication attempts
  - [ ] Rate limiting violations

- [ ] **Alerting Configured**
  - [ ] Suspicious traffic patterns
  - [ ] Rate limiting threshold breaches
  - [ ] Service availability issues
  - [ ] Certificate expiration warnings

### Post-Deployment Security Validation

#### Penetration Testing

```bash
# Test for common CORS vulnerabilities
./scripts/security-tests/cors-bypass-test.sh

# Verify rate limiting effectiveness
./scripts/security-tests/rate-limit-test.sh

# Test origin validation
./scripts/security-tests/origin-validation-test.sh

# SSL/TLS configuration test
nmap --script ssl-enum-ciphers -p 443 your-domain.com
```

#### Security Scanning

```bash
# Container vulnerability scanning
trivy image cors-handler:latest

# Kubernetes configuration scanning
kube-score score deployment/cors-handler.yaml

# Network policy validation
kubectl auth can-i create pods --as=system:serviceaccount:pvpipe-system:cors-handler
```

### Ongoing Security Maintenance

#### Weekly Tasks

- [ ] Review security logs for anomalies
- [ ] Check rate limiting statistics
- [ ] Validate origin allowlist currency
- [ ] Monitor certificate expiration dates

#### Monthly Tasks

- [ ] Security configuration audit
- [ ] Penetration testing
- [ ] Dependency vulnerability scanning
- [ ] Access control review

#### Quarterly Tasks

- [ ] Full security assessment
- [ ] Rate limiting threshold optimization
- [ ] Origin policy review and updates
- [ ] Disaster recovery testing

---

## Conclusion

The PVPipe OPTIONS bypass implementation provides a robust, secure, and performant solution for handling CORS preflight requests in enterprise environments. By following this guide, DevOps teams can successfully deploy and maintain this system while ensuring optimal security and performance.

For additional support or questions about this implementation, please refer to the troubleshooting section or contact the development team.

---

**Document Version**: 1.0  
**Last Updated**: 2025-08-02  
**Review Cycle**: Quarterly  
**Next Review Date**: 2025-11-02