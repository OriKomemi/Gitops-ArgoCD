# Configuration Management

This directory contains centralized configuration files for all Streamlit applications.

## Configuration Files

- **apps-config.yaml**: Production configuration
- **apps-config-dev.yaml**: Development environment overrides
- **apps-config-local.yaml**: Local testing configuration

## Configuration Options

### Storage Options

The configurations can be stored and managed in multiple ways:

#### 1. **ConfigMap (Recommended for Kubernetes)**
```bash
# Create ConfigMap from file
kubectl create configmap streamlit-apps-config \
  --from-file=apps-config.yaml \
  -n streamlit-apps

# Update ConfigMap
kubectl create configmap streamlit-apps-config \
  --from-file=apps-config.yaml \
  -n streamlit-apps \
  --dry-run=client -o yaml | kubectl apply -f -
```

#### 2. **Git Repository (GitOps)**
- Store configurations in Git
- ArgoCD automatically syncs changes
- Version controlled and auditable
- Current approach used in this repository

#### 3. **External Config Service**
- HashiCorp Consul
- Spring Cloud Config
- AWS AppConfig
- Azure App Configuration

#### 4. **Secret Management (for sensitive data)**
```bash
# Kubernetes Secrets
kubectl create secret generic streamlit-apps-secrets \
  --from-literal=database-password='your-password' \
  --from-literal=api-key='your-api-key' \
  -n streamlit-apps

# HashiCorp Vault
# AWS Secrets Manager
# Azure Key Vault
```

## Configuration Structure

```yaml
apps:
  <app-name>:
    name: "Display Name"
    description: "App description"
    version: "1.0.0"
    enabled: true
    port: 8501
    replicas: 2

    resources:
      requests:
        cpu: "250m"
        memory: "256Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"

    env:
      APP_NAME: "AppName"
      ENVIRONMENT: "production"
      CUSTOM_VAR: "value"

    routing:
      subdomain: "app"              # app.example.com
      path: "/app"                  # example.com/app
      enableSubdomain: true
      enablePath: true

    security:
      requireAuth: true
      allowedRoles: ["admin", "user"]

global:
  domain: "example.com"
  tlsEnabled: true
  routingStrategy: "both"           # subdomain, path, or both
  sharedService: false              # single service or per-app services
  image:
    repository: "registry/image"
    tag: "latest"
    pullPolicy: "Always"
  monitoring:
    enabled: true
    prometheus: true
  logging:
    level: "INFO"
```

## Routing Strategies

### 1. Subdomain-based Routing
Each app gets its own subdomain:
- `dashboard.example.com`
- `analytics.example.com`
- `admin.example.com`

**Pros:**
- Clean URLs
- Easy to remember
- Better isolation
- SSL certificates per subdomain

**Cons:**
- Requires wildcard DNS
- More complex DNS setup

### 2. Path-based Routing
All apps under same domain with different paths:
- `example.com/dashboard`
- `example.com/analytics`
- `example.com/admin`

**Pros:**
- Single domain/SSL certificate
- Simpler DNS setup
- Good for local testing

**Cons:**
- Longer URLs
- Potential path conflicts
- May require URL rewriting

### 3. Both (Hybrid)
Support both routing methods:
- Subdomain for production
- Path for staging/dev

## Using Configurations

### In Helm Charts

The Helm chart automatically reads these configurations and creates:
- Deployments for each enabled app
- Services (shared or individual)
- Routes/Ingress with proper routing
- ConfigMaps with app-specific settings

### In Docker Compose

```yaml
services:
  dashboard:
    environment:
      - APP_NAME=dashboard
      # Additional env vars from config
```

### Environment Variable Override

```bash
# Override configuration at runtime
kubectl set env deployment/dashboard \
  ENVIRONMENT=staging \
  -n streamlit-apps
```

## Adding a New App

1. Create app directory: `apps/newapp/`
2. Add `app.py` in the directory
3. Add configuration in `apps-config.yaml`:

```yaml
apps:
  newapp:
    name: "New App"
    version: "1.0.0"
    enabled: true
    replicas: 2
    routing:
      subdomain: "newapp"
      path: "/newapp"
```

4. Deploy with Helm:
```bash
helm upgrade streamlit-apps ./helm/streamlit-apps-multi
```

## Configuration Best Practices

1. **Environment Separation**: Use different configs per environment
2. **Secret Management**: Never commit secrets to Git
3. **Version Control**: Track configuration changes
4. **Documentation**: Document all configuration options
5. **Validation**: Validate configs before deployment
6. **Defaults**: Provide sensible defaults
7. **Immutability**: Use image tags, not `latest` in production

## Monitoring Configuration Changes

With GitOps, all configuration changes are:
- Version controlled in Git
- Reviewed via Pull Requests
- Automatically deployed by ArgoCD
- Auditable and reversible
