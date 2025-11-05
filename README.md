# Streamlit App - GitOps with ArgoCD and Helm

A complete GitOps deployment setup for a Python Streamlit application that can be deployed to OpenShift using ArgoCD and Helm.

## Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Local Testing on Mac M1](#local-testing-on-mac-m1)
  - [Test Python App Directly](#test-python-app-directly)
  - [Test with Docker](#test-with-docker)
  - [Test with Minikube and Helm](#test-with-minikube-and-helm)
  - [Test with ArgoCD Locally](#test-with-argocd-locally)
- [OpenShift Deployment](#openshift-deployment)
- [GitOps Workflow](#gitops-workflow)
- [Troubleshooting](#troubleshooting)
- [Configuration](#configuration)

## Overview

This project demonstrates a production-ready GitOps workflow for deploying a Streamlit application using:

- **Streamlit**: Python web framework for data applications
- **Docker**: Container runtime
- **Helm**: Kubernetes package manager
- **ArgoCD**: GitOps continuous delivery tool
- **OpenShift**: Enterprise Kubernetes platform

## Project Structure

```
.
├── app.py                          # Streamlit application
├── requirements.txt                # Python dependencies
├── Dockerfile                      # Container image definition
├── docker-compose.yml              # Local Docker testing
├── helm/
│   └── streamlit-app/
│       ├── Chart.yaml              # Helm chart metadata
│       ├── values.yaml             # Default values
│       ├── values-local.yaml       # Local testing values
│       ├── values-dev.yaml         # Development values
│       ├── values-prod.yaml        # Production values
│       └── templates/
│           ├── _helpers.tpl        # Helm helper functions
│           ├── deployment.yaml     # Kubernetes Deployment
│           ├── service.yaml        # Kubernetes Service
│           ├── serviceaccount.yaml # Service Account
│           ├── route.yaml          # OpenShift Route
│           ├── ingress.yaml        # Kubernetes Ingress
│           └── hpa.yaml            # Horizontal Pod Autoscaler
└── argocd/
    ├── argocd-application.yaml     # ArgoCD app for OpenShift
    └── argocd-app-local.yaml       # ArgoCD app for local testing
```

## Prerequisites

### For Local Development

- **macOS** (tested on Mac M1)
- **Python 3.9+**: `brew install python@3.9`
- **Docker Desktop**: [Download](https://www.docker.com/products/docker-desktop)
- **Minikube** or **Kind**:
  ```bash
  brew install minikube
  # OR
  brew install kind
  ```
- **Helm**: `brew install helm`
- **kubectl**: `brew install kubectl`
- **ArgoCD CLI** (optional): `brew install argocd`

### For OpenShift Deployment

- **OpenShift CLI (oc)**: [Download](https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html)
- **Access to OpenShift cluster**
- **ArgoCD installed on OpenShift**
- **Container registry** (e.g., Quay.io, Docker Hub, or internal registry)

## Local Testing on Mac M1

### Test Python App Directly

1. **Install dependencies**:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Run the application**:
   ```bash
   streamlit run app.py
   ```

3. **Access the app**:
   - Open browser: http://localhost:8501

### Test with Docker

#### Build the image

For Mac M1 (Apple Silicon), build ARM64 image:
```bash
docker build --platform linux/arm64 -t streamlit-app:latest .
```

For multi-platform build:
```bash
docker buildx build --platform linux/amd64,linux/arm64 -t streamlit-app:latest .
```

#### Run with Docker

**Option 1: Docker run**
```bash
docker run -p 8501:8501 streamlit-app:latest
```

**Option 2: Docker Compose**
```bash
docker-compose up
```

#### Access the app
- Open browser: http://localhost:8501

#### Stop and cleanup
```bash
docker-compose down
# OR
docker stop $(docker ps -q --filter ancestor=streamlit-app:latest)
```

### Test with Minikube and Helm

#### 1. Start Minikube

```bash
# Start Minikube with sufficient resources
minikube start --cpus 4 --memory 8192 --driver=docker

# Enable required addons
minikube addons enable ingress
minikube addons enable metrics-server
```

#### 2. Build and load image

```bash
# Build the image
docker build -t streamlit-app:latest .

# Load image into Minikube
minikube image load streamlit-app:latest

# Verify the image is loaded
minikube image ls | grep streamlit-app
```

#### 3. Deploy with Helm

```bash
# Create namespace
kubectl create namespace streamlit-app-local

# Install the Helm chart
helm install streamlit-app ./helm/streamlit-app \
  --namespace streamlit-app-local \
  --values ./helm/streamlit-app/values-local.yaml

# Check deployment status
kubectl get pods -n streamlit-app-local
kubectl get svc -n streamlit-app-local
```

#### 4. Access the application

**Option 1: NodePort (recommended for local)**
```bash
# Get the NodePort
kubectl get svc streamlit-app -n streamlit-app-local

# Get Minikube IP
minikube ip

# Access via: http://<minikube-ip>:<node-port>
# OR use Minikube service command
minikube service streamlit-app -n streamlit-app-local
```

**Option 2: Port forwarding**
```bash
kubectl port-forward svc/streamlit-app 8501:8501 -n streamlit-app-local
# Access via: http://localhost:8501
```

#### 5. Upgrade the chart

```bash
# Make changes to your values or templates
helm upgrade streamlit-app ./helm/streamlit-app \
  --namespace streamlit-app-local \
  --values ./helm/streamlit-app/values-local.yaml
```

#### 6. Cleanup

```bash
# Uninstall the release
helm uninstall streamlit-app -n streamlit-app-local

# Delete namespace
kubectl delete namespace streamlit-app-local

# Stop Minikube
minikube stop
```

### Test with ArgoCD Locally

#### 1. Install ArgoCD in Minikube

```bash
# Start Minikube
minikube start --cpus 4 --memory 8192

# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server -n argocd
```

#### 2. Access ArgoCD UI

```bash
# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# Port forward to ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Login via browser: https://localhost:8080
# Username: admin
# Password: <from above command>
```

#### 3. Login with ArgoCD CLI (optional)

```bash
# Login
argocd login localhost:8080

# Change password (recommended)
argocd account update-password
```

#### 4. Prepare your application

```bash
# Build and load image into Minikube
docker build -t streamlit-app:latest .
minikube image load streamlit-app:latest

# Push your code to Git repository
git add .
git commit -m "Initial commit"
git push
```

#### 5. Deploy application with ArgoCD

**Option 1: Using ArgoCD UI**
1. Open ArgoCD UI: https://localhost:8080
2. Click "New App"
3. Fill in the details:
   - Application Name: `streamlit-app-local`
   - Project: `default`
   - Sync Policy: `Automatic`
   - Repository URL: `https://github.com/OriKomemi/Gitops-ArgoCD.git`
   - Path: `helm/streamlit-app`
   - Cluster: `https://kubernetes.default.svc`
   - Namespace: `streamlit-app-local`
   - Values File: `values-local.yaml`

**Option 2: Using kubectl**
```bash
# Update the argocd-app-local.yaml with your repo URL
kubectl apply -f argocd/argocd-app-local.yaml
```

**Option 3: Using ArgoCD CLI**
```bash
argocd app create streamlit-app-local \
  --repo https://github.com/OriKomemi/Gitops-ArgoCD.git \
  --path helm/streamlit-app \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace streamlit-app-local \
  --values values-local.yaml \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

#### 6. Monitor deployment

```bash
# Watch application status
argocd app get streamlit-app-local

# Watch sync status
argocd app sync streamlit-app-local --watch

# Check pods
kubectl get pods -n streamlit-app-local

# View logs
kubectl logs -f deployment/streamlit-app-local -n streamlit-app-local
```

#### 7. Access the application

```bash
# Get service
minikube service streamlit-app-local -n streamlit-app-local

# OR port forward
kubectl port-forward svc/streamlit-app-local 8501:8501 -n streamlit-app-local
```

#### 8. Test GitOps workflow

```bash
# Make changes to the Helm values or app code
vim helm/streamlit-app/values-local.yaml

# Commit and push
git add .
git commit -m "Update configuration"
git push

# ArgoCD will automatically detect and sync changes
# Watch the sync in ArgoCD UI or CLI
argocd app sync streamlit-app-local --watch
```

#### 9. Cleanup

```bash
# Delete application
argocd app delete streamlit-app-local
# OR
kubectl delete -f argocd/argocd-app-local.yaml

# Uninstall ArgoCD (optional)
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
```

## OpenShift Deployment

### Prerequisites

1. **OpenShift cluster access**:
   ```bash
   oc login --token=<your-token> --server=https://api.your-cluster.com:6443
   ```

2. **ArgoCD installed** on your OpenShift cluster

3. **Container image** pushed to a registry accessible by OpenShift

### Step 1: Build and Push Container Image

```bash
# Login to your container registry
docker login your-registry.example.com

# Build for AMD64 (OpenShift typically runs on x86_64)
docker buildx build --platform linux/amd64 \
  -t your-registry.example.com/streamlit-app:1.0.0 \
  --push .

# OR build and push separately
docker build --platform linux/amd64 \
  -t your-registry.example.com/streamlit-app:1.0.0 .
docker push your-registry.example.com/streamlit-app:1.0.0
```

### Step 2: Update Helm Values

Update `helm/streamlit-app/values-dev.yaml` or `values-prod.yaml`:

```yaml
image:
  repository: your-registry.example.com/streamlit-app
  tag: "1.0.0"

route:
  host: streamlit-app-dev.apps.your-cluster.example.com
```

### Step 3: Configure ArgoCD Application

Update `argocd/argocd-application.yaml`:

```yaml
spec:
  source:
    repoURL: https://github.com/OriKomemi/Gitops-ArgoCD.git
    helm:
      valueFiles:
        - values-dev.yaml  # or values-prod.yaml
      parameters:
        - name: image.repository
          value: your-registry.example.com/streamlit-app
        - name: image.tag
          value: "1.0.0"
```

### Step 4: Deploy with ArgoCD

**Option 1: Using OpenShift Console**
1. Navigate to ArgoCD UI
2. Create new application using the manifest

**Option 2: Using kubectl/oc**
```bash
# Apply the ArgoCD application
oc apply -f argocd/argocd-application.yaml

# Check application status
oc get application -n argocd
```

**Option 3: Using ArgoCD CLI**
```bash
# Login to ArgoCD
argocd login argocd-server.argocd.svc.cluster.local

# Create application from file
argocd app create -f argocd/argocd-application.yaml

# Sync application
argocd app sync streamlit-app
```

### Step 5: Verify Deployment

```bash
# Check application status
oc get pods -n streamlit-app-dev
oc get route -n streamlit-app-dev

# View logs
oc logs -f deployment/streamlit-app -n streamlit-app-dev

# Get route URL
oc get route streamlit-app -n streamlit-app-dev -o jsonpath='{.spec.host}'
```

### Step 6: Access Application

```bash
# Get the route URL
export APP_URL=$(oc get route streamlit-app -n streamlit-app-dev -o jsonpath='{.spec.host}')
echo "https://$APP_URL"

# Open in browser
open "https://$APP_URL"
```

## GitOps Workflow

### Making Changes

1. **Update code or configuration**:
   ```bash
   # Edit application code
   vim app.py

   # OR update Helm values
   vim helm/streamlit-app/values-dev.yaml
   ```

2. **Commit and push**:
   ```bash
   git add .
   git commit -m "Update application configuration"
   git push origin main
   ```

3. **ArgoCD automatically syncs** (if auto-sync enabled):
   - Detects changes in Git repository
   - Applies changes to cluster
   - Monitors health status

4. **Manual sync** (if needed):
   ```bash
   argocd app sync streamlit-app
   ```

### Promoting Across Environments

1. **Test in dev**:
   ```bash
   # Use values-dev.yaml
   argocd app set streamlit-app --values values-dev.yaml
   ```

2. **Deploy to production**:
   ```bash
   # Update to use values-prod.yaml
   argocd app set streamlit-app --values values-prod.yaml
   argocd app sync streamlit-app
   ```

### Rolling Back

```bash
# View history
argocd app history streamlit-app

# Rollback to previous version
argocd app rollback streamlit-app <history-id>
```

## Troubleshooting

### Common Issues

#### Pods not starting

```bash
# Check pod status
kubectl get pods -n <namespace>

# Describe pod
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

#### Image pull errors

```bash
# Check image pull secrets
kubectl get secrets -n <namespace>

# Describe deployment
kubectl describe deployment <deployment-name> -n <namespace>

# Verify image exists
docker pull <image-repository>:<tag>
```

#### Health check failures

```bash
# Check probe configuration
kubectl describe pod <pod-name> -n <namespace>

# Test health endpoint manually
kubectl exec -it <pod-name> -n <namespace> -- curl localhost:8501/_stcore/health

# Adjust probe timings in values.yaml:
livenessProbe:
  initialDelaySeconds: 60  # Increase if needed
  failureThreshold: 5
```

#### ArgoCD sync issues

```bash
# Check application status
argocd app get streamlit-app

# View sync errors
argocd app sync streamlit-app --dry-run

# Force sync
argocd app sync streamlit-app --force

# Refresh application
argocd app refresh streamlit-app
```

### Debugging Commands

```bash
# Helm commands
helm list -n <namespace>
helm get values <release-name> -n <namespace>
helm get manifest <release-name> -n <namespace>

# Kubernetes commands
kubectl get all -n <namespace>
kubectl describe deployment <deployment-name> -n <namespace>
kubectl logs -f deployment/<deployment-name> -n <namespace>

# OpenShift commands
oc status -n <namespace>
oc get route -n <namespace>
oc logs -f dc/<deployment-name> -n <namespace>
```

### Viewing ArgoCD Logs

```bash
# ArgoCD application controller logs
kubectl logs -f deployment/argocd-application-controller -n argocd

# ArgoCD server logs
kubectl logs -f deployment/argocd-server -n argocd

# ArgoCD repo server logs
kubectl logs -f deployment/argocd-repo-server -n argocd
```

## Configuration

### Resource Limits

Adjust in `values.yaml` or environment-specific values:

```yaml
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

### Autoscaling

Enable in `values-prod.yaml`:

```yaml
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

### Custom Environment Variables

Add to `values.yaml`:

```yaml
env:
  - name: CUSTOM_VAR
    value: "custom-value"
```

### TLS Configuration

For OpenShift Route:

```yaml
route:
  tls:
    enabled: true
    termination: edge
    insecureEdgeTerminationPolicy: Redirect
```

## Security Best Practices

1. **Non-root user**: Application runs as UID 1001
2. **Read-only root filesystem**: Security context configured
3. **Resource limits**: CPU and memory limits defined
4. **Health checks**: Liveness and readiness probes configured
5. **TLS enabled**: HTTPS for external access
6. **Security Context Constraints**: Compatible with OpenShift restricted SCC

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally
5. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

For issues and questions:
- Open an issue on GitHub
- Contact: devops@example.com
