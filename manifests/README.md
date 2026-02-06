# Kubernetes Manifests Deployment Guide

This directory contains Kubernetes YAML manifests for deploying the hello-world application to your EKS cluster.

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **kubectl** installed and configured
3. **EKS cluster** already created and kubeconfig updated
4. **Docker image** pushed to ECR

## Files

- `hello-world-ns.yaml` - Creates the hello-world-ns namespace
- `hello-world-deployment.yaml` - Deployment configuration with 3 replicas
- `hello-world-service.yaml` - LoadBalancer service (NLB) configuration

## Quick Start

### Using Makefile (Recommended)

```bash
# Validate manifests before deploying
make k8s-validate

# Deploy all manifests
make k8s-apply

# Check deployment status
make k8s-status

# View logs
make k8s-logs

# Restart deployment
make k8s-restart

# Delete all resources
make k8s-delete
```

### Using kubectl Directly

```bash
# Apply manifests in order
kubectl apply -f manifests/hello-world-ns.yaml
kubectl apply -f manifests/hello-world-deployment.yaml
kubectl apply -f manifests/hello-world-service.yaml

# Check status
kubectl get all -n hello-world-ns

# Get LoadBalancer URL
kubectl get service hello-world-service -n hello-world-ns

# Delete resources
kubectl delete -f manifests/hello-world-service.yaml
kubectl delete -f manifests/hello-world-deployment.yaml
kubectl delete -f manifests/hello-world-ns.yaml
```

## Validating Manifests

Before deploying, it's recommended to validate your manifests to catch syntax errors and configuration issues.

### Client-Side Validation (No Cluster Required)

```bash
# Validate using Makefile
make k8s-validate

# Or validate individual files with kubectl
kubectl apply --dry-run=client -f manifests/hello-world-ns.yaml
kubectl apply --dry-run=client -f manifests/hello-world-deployment.yaml
kubectl apply --dry-run=client -f manifests/hello-world-service.yaml

# Validate kustomize configuration
make k8s-kustomize-validate
```

### Server-Side Validation (Requires Cluster Connection)

Server-side validation performs additional checks against the actual Kubernetes API, including admission controllers and validation webhooks.

```bash
# Validate against cluster
make k8s-validate-server

# Or with kubectl
kubectl apply --dry-run=server -f manifests/hello-world-deployment.yaml
```

### What Gets Validated

- ✅ YAML syntax correctness
- ✅ Kubernetes resource schema compliance
- ✅ Required fields presence
- ✅ Field type validation
- ✅ Resource constraints (limits/requests)
- ✅ Label selectors matching
- ⚠️ Server-side only: Admission policies, quotas, custom validation

## Updating the Docker Image

Before deploying, update the image reference in `hello-world-deployment.yaml`:

```yaml
# Replace with your actual image
image: <account-id>.dkr.ecr.<region>.amazonaws.com/hello-world-demo:<tag>
```

### Using the update script

```bash
# Update with image digest (recommended for production)
./scripts/update-manifest-image.sh hello-world-demo 1.2.5

# Or update without digest
./scripts/update-manifest-image.sh hello-world-demo 1.2.5 --no-digest
```

## Deployment Configuration

### Resource Limits

- CPU: 100m limit, 50m request
- Memory: 64Mi limit, 32Mi request

### Replicas

- Default: 3 replicas
- RollingUpdate strategy with maxSurge: 1, maxUnavailable: 1

### Health Checks

- Liveness probe: HTTP GET / on port 8080 (10s initial delay, 10s period)
- Readiness probe: HTTP GET / on port 8080 (5s initial delay, 5s period)

### Security

- Runs as non-root user (UID 10001)
- Read-only root filesystem
- Drops all capabilities
- RuntimeDefault seccomp profile

### Service

- Type: LoadBalancer (AWS Network Load Balancer)
- Scheme: internet-facing
- Target type: IP
- Port: 80 (external) → 8080 (container)

## Monitoring

```bash
# Watch pods
kubectl get pods -n hello-world-ns -w

# Describe deployment
kubectl describe deployment hello-world -n hello-world-ns

# View events
kubectl get events -n hello-world-ns --sort-by='.lastTimestamp'

# Check service endpoint
kubectl get service hello-world-service -n hello-world-ns -o wide
```

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod <pod-name> -n hello-world-ns
kubectl logs <pod-name> -n hello-world-ns
```

### LoadBalancer not provisioning

```bash
kubectl describe service hello-world-service -n hello-world-ns
# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Image pull errors

```bash
# Verify ECR repository exists and image is pushed
aws ecr describe-images --repository-name hello-world-demo --region us-east-1

# Check if nodes have ECR access (IAM role permissions)
kubectl describe node | grep InstanceProfile
```

## Migration from Terraform

The manifests in this directory are equivalent to the Terraform configuration in `terraform/deploys.tf`. To migrate:

1. **Ensure EKS cluster exists** (still managed by Terraform in `terraform/eks.tf`)
2. **Update kubeconfig**: Run `scripts/update-kubeconfig.sh`
3. **Update image reference** in `hello-world-deployment.yaml`
4. **Deploy manifests**: Run `make k8s-apply`
5. **Remove Terraform resources** (optional): Comment out or remove the kubernetes_* resources from `terraform/deploys.tf`

### Key Differences

- **Image management**: In manifests, you manually update the image tag/digest. In Terraform, it was dynamically resolved.
- **No state management**: kubectl applies changes directly; Terraform tracks state.
- **Faster iteration**: Changes can be applied immediately without `terraform plan/apply`.

## Comparison: Terraform vs Manifests

| Aspect | Terraform | Manifests |
| ------ | --------- | --------- |
| **State tracking** | Yes (S3 backend) | No |
| **Dependency management** | Explicit (depends_on) | Manual ordering |
| **Variables** | Supported | Must use templating tools |
| **Drift detection** | terraform plan | kubectl diff |
| **Roll back** | terraform state | kubectl rollout undo |
| **Infrastructure** | EKS + Kubernetes | Kubernetes only |

## Best Practices

1. **Version control**: Always commit manifest changes
2. **Image digests**: Use SHA256 digests for production deployments
3. **Namespace isolation**: Keep different environments in separate namespaces
4. **Resource limits**: Always define limits and requests
5. **Health checks**: Configure liveness and readiness probes
6. **Security**: Follow least-privilege principle
7. **GitOps**: Consider using ArgoCD or Flux for automated deployments
