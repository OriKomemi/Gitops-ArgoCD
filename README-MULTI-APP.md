# Multi-App Streamlit Deployment with GitOps

Complete guide for deploying multiple Streamlit applications using a single Helm chart with flexible routing options (subdomain and path-based).

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Routing Strategies](#routing-strategies)
- [Configuration Management](#configuration-management)
- [Quick Start](#quick-start)
- [Local Testing](#local-testing)
- [OpenShift Deployment](#openshift-deployment)
- [Adding New Apps](#adding-new-apps)
- [Troubleshooting](#troubleshooting)

## Overview

This setup allows you to deploy multiple Streamlit applications from a single Helm chart with:

- **Flexible Routing**: Subdomain (`app.domain.com`) or path-based (`domain.com/app`)
- **Centralized Configuration**: YAML-based config management
- **Individual or Shared Services**: Deploy with separate or shared Kubernetes services
- **Auto-scaling**: Per-app horizontal pod autoscaling
- **GitOps Ready**: Full ArgoCD integration

### Currently Deployed Apps

1. **Dashboard** (`/dashboard` or `dashboard.example.com`) - Main dashboard application
2. **Analytics** (`/analytics` or `analytics.example.com`) - Analytics and reporting
3. **Admin** (`/admin` or `admin.example.com`) - Administration panel

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     OpenShift/K8s                        │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Dashboard   │  │  Analytics   │  │    Admin     │ │
│  │  Deployment  │  │  Deployment  │  │  Deployment  │ │
│  │  (2-8 pods)  │  │  (3-15 pods) │  │  (2-5 pods)  │ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │
│         │                 │                  │          │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐ │
│  │   Service    │  │   Service    │  │   Service    │ │
│  │  dashboard   │  │  analytics   │  │    admin     │ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │
│         │                 │                  │          │
│         └─────────────────┴──────────────────┘          │
│                           │                             │
│              ┌────────────▼────────────┐                │
│              │  OpenShift Route or     │                │
│              │  Kubernetes Ingress     │                │
│              └────────────┬────────────┘                │
└───────────────────────────┼─────────────────────────────┘
                            │
                    ┌───────▼────────┐
                    │  External DNS  │
                    └────────────────┘

      Subdomain:                    Path-based:
  dashboard.domain.com          domain.com/dashboard
  analytics.domain.com          domain.com/analytics
  admin.domain.com              domain.com/admin
```

## Project Structure

```
.
├── apps/                           # Application code
│   ├── dashboard/
│   │   └── app.py                 # Dashboard Streamlit app
│   ├── analytics/
│   │   └── app.py                 # Analytics Streamlit app
│   └── admin/
│       └── app.py                 # Admin Streamlit app
│
├── config/                         # Centralized configuration
│   ├── apps-config.yaml           # Production config
│   ├── apps-config-dev.yaml       # Development config
│   ├── apps-config-local.yaml     # Local testing config
│   └── README.md                  # Configuration guide
│
├── helm/streamlit-apps-multi/     # Multi-app Helm chart
│   ├── Chart.yaml
│   ├── values.yaml                # Default values
│   ├── values-local.yaml          # Local testing values
│   ├── values-dev.yaml            # Development values
│   ├── values-prod.yaml           # Production values
│   └── templates/
│       ├── _helpers.tpl           # Helper functions
│       ├── configmap.yaml         # App configuration
│       ├── deployment.yaml        # Dynamic deployments
│       ├── service.yaml           # Dynamic services
│       ├── route.yaml             # OpenShift routes
│       ├── ingress.yaml           # Kubernetes ingress
│       ├── hpa.yaml               # Autoscaling
│       └── serviceaccount.yaml    # Service account
│
├── argocd/
│   ├── argocd-multi-app.yaml      # Dev ArgoCD application
│   └── argocd-multi-app-prod.yaml # Prod ArgoCD application
│
├── Dockerfile.multi-app            # Multi-app container image
├── docker-entrypoint.sh            # Dynamic app selector
├── docker-compose.multi-app.yml    # Local multi-app testing
├── nginx.conf                      # Nginx reverse proxy config
└── README-MULTI-APP.md            # This file
```

## Routing Strategies

### 1. Subdomain Routing (Recommended for Production)

Each app gets its own subdomain:
```
dashboard.example.com  → Dashboard App
analytics.example.com  → Analytics App
admin.example.com      → Admin App
```

**Configuration:**
```yaml
global:
  routingStrategy: "subdomain"
  domain: "example.com"

apps:
  dashboard:
    routing:
      subdomain: "dashboard"
      enableSubdomain: true
```

**Pros:**
- Clean URLs
- Better isolation
- Independent SSL certificates
- Easier to manage separate apps

**Cons:**
- Requires wildcard DNS configuration
- May need wildcard SSL certificate

### 2. Path-based Routing (Good for Local/Dev)

All apps under single domain with different paths:
```
example.com/dashboard  → Dashboard App
example.com/analytics  → Analytics App
example.com/admin      → Admin App
```

**Configuration:**
```yaml
global:
  routingStrategy: "path"
  domain: "example.com"

apps:
  dashboard:
    routing:
      path: "/dashboard"
      enablePath: true
```

**Pros:**
- Single domain and SSL certificate
- Simpler DNS setup
- Great for local testing

**Cons:**
- Longer URLs
- May require URL rewriting
- Potential path conflicts

### 3. Hybrid (Both Methods)

Support both routing methods simultaneously:
```yaml
global:
  routingStrategy: "both"
```

This creates routes for:
- `dashboard.example.com` (subdomain)
- `example.com/dashboard` (path)

## Configuration Management

### Configuration Storage Options

#### 1. Git Repository (Current - GitOps)
```bash
# Configurations stored in config/ directory
# Changes tracked in Git
# ArgoCD automatically syncs
```

#### 2. Kubernetes ConfigMap
```bash
# Create ConfigMap
kubectl create configmap apps-config \
  --from-file=config/apps-config.yaml \
  -n streamlit-apps

# Apps read from ConfigMap
```

#### 3. External Config Service
- HashiCorp Consul
- Spring Cloud Config
- AWS AppConfig
- Azure App Configuration

### Configuration Structure

See `config/README.md` for detailed configuration options.

**Example app configuration:**
```yaml
apps:
  myapp:
    enabled: true
    name: "My App"
    version: "1.0.0"
    replicas: 3

    resources:
      limits:
        cpu: "500m"
        memory: "512Mi"

    routing:
      subdomain: "myapp"
      path: "/myapp"
      enableSubdomain: true
      enablePath: true

    env:
      - name: CUSTOM_VAR
        value: "custom-value"
```

## Quick Start

### Build Multi-App Image

```bash
# Build the multi-app Docker image
docker build -f Dockerfile.multi-app -t streamlit-apps:latest .

# For Mac M1/Apple Silicon
docker build --platform linux/arm64 \
  -f Dockerfile.multi-app \
  -t streamlit-apps:latest .
```

### Test Single App Locally

```bash
# Run dashboard app
docker run -p 8501:8501 \
  -e APP_NAME=dashboard \
  -e ENVIRONMENT=local \
  streamlit-apps:latest

# Run analytics app
docker run -p 8502:8501 \
  -e APP_NAME=analytics \
  -e ENVIRONMENT=local \
  streamlit-apps:latest

# Access at:
# Dashboard: http://localhost:8501
# Analytics: http://localhost:8502
```

## Local Testing

### Option 1: Docker Compose (All Apps)

```bash
# Start all apps
docker-compose -f docker-compose.multi-app.yml up

# Access apps:
# Dashboard: http://localhost:8501
# Analytics: http://localhost:8502
# Admin: http://localhost:8503
# Nginx proxy (path-based): http://localhost:8080/dashboard

# Stop all apps
docker-compose -f docker-compose.multi-app.yml down
```

### Option 2: Minikube with Helm

#### Start Minikube

```bash
minikube start --cpus 4 --memory 8192
minikube addons enable ingress
```

#### Build and Load Image

```bash
# Build image
docker build -f Dockerfile.multi-app -t streamlit-apps:latest .

# Load into Minikube
minikube image load streamlit-apps:latest

# Verify
minikube image ls | grep streamlit-apps
```

#### Deploy with Helm

```bash
# Create namespace
kubectl create namespace streamlit-apps-local

# Install Helm chart
helm install streamlit-apps ./helm/streamlit-apps-multi \
  -n streamlit-apps-local \
  -f ./helm/streamlit-apps-multi/values-local.yaml

# Check status
kubectl get pods -n streamlit-apps-local
kubectl get svc -n streamlit-apps-local
```

#### Access Applications

```bash
# Get NodePort services
kubectl get svc -n streamlit-apps-local

# Access via Minikube service
minikube service streamlit-apps-multi-dashboard -n streamlit-apps-local
minikube service streamlit-apps-multi-analytics -n streamlit-apps-local
minikube service streamlit-apps-multi-admin -n streamlit-apps-local

# Or use port forwarding
kubectl port-forward svc/streamlit-apps-multi-dashboard 8501:8501 -n streamlit-apps-local
# Access: http://localhost:8501
```

### Option 3: Minikube with ArgoCD

#### Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server -n argocd

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# Port forward to UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

#### Deploy Apps with ArgoCD

```bash
# Build and load image first
docker build -f Dockerfile.multi-app -t streamlit-apps:latest .
minikube image load streamlit-apps:latest

# Apply ArgoCD application
# First, update argocd/argocd-multi-app.yaml with your repo URL
kubectl apply -f argocd/argocd-multi-app.yaml

# Check sync status
kubectl get applications -n argocd

# Access ArgoCD UI
# Open: https://localhost:8080
# Login: admin / <password from above>
```

## OpenShift Deployment

### Prerequisites

1. **OpenShift cluster access**
2. **Container registry** (Quay.io, Docker Hub, or internal)
3. **ArgoCD installed** on OpenShift

### Step 1: Build and Push Image

```bash
# Login to registry
docker login your-registry.example.com

# Build for AMD64 (OpenShift)
docker buildx build --platform linux/amd64 \
  -f Dockerfile.multi-app \
  -t your-registry.example.com/streamlit-apps:1.0.0 \
  --push .
```

### Step 2: Update Configuration

Edit `helm/streamlit-apps-multi/values-prod.yaml`:

```yaml
global:
  domain: "apps.openshift.example.com"
  image:
    repository: "your-registry.example.com/streamlit-apps"
    tag: "1.0.0"
```

### Step 3: Configure ArgoCD

Update `argocd/argocd-multi-app-prod.yaml`:

```yaml
spec:
  source:
    helm:
      valueFiles:
        - values-prod.yaml
      parameters:
        - name: global.domain
          value: apps.openshift.example.com
```

### Step 4: Deploy

```bash
# Login to OpenShift
oc login --token=<token> --server=https://api.cluster.com:6443

# Apply ArgoCD application
oc apply -f argocd/argocd-multi-app-prod.yaml

# Check status
oc get pods -n streamlit-apps-prod
oc get routes -n streamlit-apps-prod

# Get URLs
oc get route -n streamlit-apps-prod -o jsonpath='{range .items[*]}{.spec.host}{"\n"}{end}'
```

### Step 5: Verify Deployment

```bash
# Check all apps
oc get all -n streamlit-apps-prod -l app.kubernetes.io/instance=streamlit-apps-multi

# Check individual app
oc get pods -n streamlit-apps-prod -l app=dashboard
oc logs -f deployment/streamlit-apps-multi-dashboard -n streamlit-apps-prod

# Test endpoints
curl https://dashboard.apps.openshift.example.com/_stcore/health
curl https://analytics.apps.openshift.example.com/_stcore/health
curl https://admin.apps.openshift.example.com/_stcore/health
```

## Adding New Apps

### 1. Create App Code

```bash
# Create new app directory
mkdir -p apps/newapp

# Create app.py
cat > apps/newapp/app.py << 'EOF'
import streamlit as st
import os

st.set_page_config(page_title="New App", page_icon="🚀")

app_config = {
    "app_name": os.getenv("APP_NAME", "NewApp"),
    "version": os.getenv("APP_VERSION", "1.0.0")
}

st.title(f"🚀 {app_config['app_name']}")
st.write("Your new app content here")
EOF
```

### 2. Add to Configuration

Edit `config/apps-config.yaml`:

```yaml
apps:
  newapp:
    name: "New App"
    version: "1.0.0"
    enabled: true
    port: 8501
    replicas: 2
    routing:
      subdomain: "newapp"
      path: "/newapp"
      enableSubdomain: true
      enablePath: true
    env:
      APP_NAME: "NewApp"
      ENVIRONMENT: "production"
```

### 3. Add to Helm Values

Edit `helm/streamlit-apps-multi/values.yaml`:

```yaml
apps:
  newapp:
    enabled: true
    name: "New App"
    appName: "newapp"
    version: "1.0.0"
    replicaCount: 2
    service:
      type: ClusterIP
      port: 8501
    routing:
      subdomain: "newapp"
      path: "/newapp"
      enableSubdomain: true
      enablePath: true
    resources:
      limits:
        cpu: 500m
        memory: 512Mi
      requests:
        cpu: 250m
        memory: 256Mi
    # ... other settings
```

### 4. Test Locally

```bash
# Rebuild image
docker build -f Dockerfile.multi-app -t streamlit-apps:latest .

# Test new app
docker run -p 8504:8501 \
  -e APP_NAME=newapp \
  -e ENVIRONMENT=local \
  streamlit-apps:latest

# Access: http://localhost:8504
```

### 5. Deploy

```bash
# Commit changes
git add apps/newapp config/apps-config.yaml helm/streamlit-apps-multi/values.yaml
git commit -m "Add new app: newapp"
git push

# ArgoCD will automatically sync (if auto-sync enabled)
# Or manually sync
argocd app sync streamlit-apps-multi
```

## Troubleshooting

### Common Issues

#### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n streamlit-apps-prod

# Describe pod
kubectl describe pod <pod-name> -n streamlit-apps-prod

# Check logs
kubectl logs <pod-name> -n streamlit-apps-prod

# Common causes:
# - Image pull errors
# - Invalid APP_NAME environment variable
# - Resource limits too low
```

#### App Not Accessible

```bash
# Check services
kubectl get svc -n streamlit-apps-prod

# Check routes/ingress
oc get routes -n streamlit-apps-prod  # OpenShift
kubectl get ingress -n streamlit-apps-prod  # Kubernetes

# Test service connectivity
kubectl run test-pod --rm -it --image=busybox -- \
  wget -O- http://streamlit-apps-multi-dashboard:8501/_stcore/health

# Check DNS
nslookup dashboard.apps.openshift.example.com
```

#### Path-based Routing Not Working

```bash
# Check annotations on route/ingress
kubectl describe ingress streamlit-apps-multi-path -n streamlit-apps-prod

# Verify rewrite rules are applied
# For nginx ingress:
kubectl get ingress streamlit-apps-multi-path -n streamlit-apps-prod -o yaml | \
  grep -A5 annotations

# For OpenShift routes:
oc get route streamlit-apps-multi-dashboard-path -n streamlit-apps-prod -o yaml | \
  grep -A5 annotations
```

#### ArgoCD Sync Issues

```bash
# Check application status
argocd app get streamlit-apps-multi

# View detailed sync status
argocd app sync streamlit-apps-multi --dry-run

# Force sync
argocd app sync streamlit-apps-multi --force

# Refresh and hard refresh
argocd app refresh streamlit-apps-multi --hard
```

### Debug Commands

```bash
# Helm debugging
helm template streamlit-apps ./helm/streamlit-apps-multi \
  -f ./helm/streamlit-apps-multi/values-dev.yaml \
  --debug

# Check generated manifests
helm get manifest streamlit-apps -n streamlit-apps-prod

# Validate Helm chart
helm lint ./helm/streamlit-apps-multi

# Check resource usage
kubectl top pods -n streamlit-apps-prod
kubectl describe hpa -n streamlit-apps-prod
```

### Logs and Monitoring

```bash
# Stream logs from all apps
kubectl logs -f -l app.kubernetes.io/instance=streamlit-apps-multi \
  -n streamlit-apps-prod --all-containers=true

# Stream logs from specific app
kubectl logs -f -l app=dashboard -n streamlit-apps-prod

# Check events
kubectl get events -n streamlit-apps-prod --sort-by='.lastTimestamp'

# Port forward for debugging
kubectl port-forward deployment/streamlit-apps-multi-dashboard \
  8501:8501 -n streamlit-apps-prod
```

## Performance Tuning

### Resource Optimization

```yaml
# Adjust resources based on app needs
apps:
  analytics:  # Resource-intensive app
    resources:
      limits:
        cpu: 2000m
        memory: 4Gi
      requests:
        cpu: 1000m
        memory: 2Gi

  dashboard:  # Lightweight app
    resources:
      limits:
        cpu: 300m
        memory: 384Mi
      requests:
        cpu: 150m
        memory: 192Mi
```

### Autoscaling Configuration

```yaml
apps:
  analytics:
    autoscaling:
      enabled: true
      minReplicas: 5
      maxReplicas: 20
      targetCPUUtilizationPercentage: 65
      targetMemoryUtilizationPercentage: 70
```

### Caching and Performance

```yaml
apps:
  dashboard:
    env:
      - name: STREAMLIT_SERVER_ENABLE_STATIC_SERVING
        value: "true"
      - name: STREAMLIT_SERVER_MAX_UPLOAD_SIZE
        value: "200"
```

## Security

### Network Policies

```bash
# Create network policy to restrict traffic
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: streamlit-apps-netpol
  namespace: streamlit-apps-prod
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/instance: streamlit-apps-multi
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: openshift-ingress
      ports:
        - protocol: TCP
          port: 8501
EOF
```

### Secret Management

```bash
# Create secrets for sensitive data
kubectl create secret generic streamlit-secrets \
  --from-literal=db-password='secure-password' \
  --from-literal=api-key='your-api-key' \
  -n streamlit-apps-prod

# Reference in values.yaml
envFrom:
  - secretRef:
      name: streamlit-secrets
```

## Best Practices

1. **Use specific image tags** in production (not `latest`)
2. **Enable autoscaling** for variable workloads
3. **Set proper resource limits** to prevent resource exhaustion
4. **Use subdomain routing** for production
5. **Enable monitoring** (Prometheus/Grafana)
6. **Implement health checks** properly
7. **Use ConfigMaps** for configuration
8. **Separate environments** (dev, staging, prod)
9. **Version control** all configurations
10. **Test locally** before deploying

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add your app to `apps/` directory
4. Update configurations
5. Test locally
6. Submit pull request

## License

MIT License

## Support

For issues and questions:
- Open an issue on GitHub
- Check documentation in `config/README.md`
- Review Helm chart values
