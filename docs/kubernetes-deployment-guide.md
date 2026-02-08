# Kubernetes Deployment Guide

This guide covers deploying the hello-world application to your EKS cluster using Kubernetes manifests.

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **kubectl** installed (v1.28+)
3. **EKS cluster** provisioned via Terraform
4. **kubeconfig** updated to point to your cluster
5. **Docker image** built and pushed to ECR

## Manifest Files

Located in the `manifests/` directory:

- **`hello-world-ns.yaml`** - Namespace definition
- **`hello-world-deployment.yaml`** - 3-replica deployment with security hardening
- **`hello-world-service.yaml`** - Network Load Balancer service
- **`kustomization.yaml`** - Kustomize configuration (optional)

## Current Configuration

### Image

- **Repository**: `802645170184.dkr.ecr.us-east-1.amazonaws.com/hello-world-demo`
- **Tag**: `1.3.2`
- **Platform**: linux/amd64
- **Base**: nginx:alpine

### Security Features

- Non-root user (UID 101)
- Read-only root filesystem
- Writable volumes for cache, run, and SSL
- Dropped ALL capabilities
- No privilege escalation
- Runtime default seccomp profile

### Ports & TLS

- **HTTP**: 8080 (container) → 80 (load balancer)
- **HTTPS**: 8443 (container) → 443 (load balancer)
- **TLS**: Self-signed certificates generated at runtime

### Resources

- **CPU**: 100m limit, 50m request
- **Memory**: 64Mi limit, 32Mi request
- **Replicas**: 3 with rolling update strategy

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

# Open shell in running container
make k8s-shell

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
kubectl get service hello-world-service -n hello-world-ns \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Delete resources (reverse order)
kubectl delete -f manifests/hello-world-service.yaml
kubectl delete -f manifests/hello-world-deployment.yaml
kubectl delete -f manifests/hello-world-ns.yaml
```

### Using Kustomize

```bash
# Validate
make k8s-kustomize-validate

# Deploy
make k8s-kustomize-apply

# View diff
make k8s-kustomize-diff

# Delete
make k8s-kustomize-delete
```

## Validating Manifests

### Client-Side Validation

Validates syntax and schema without connecting to cluster:

```bash
# Validate all manifests
make k8s-validate

# Or individually
kubectl apply --dry-run=client -f manifests/hello-world-deployment.yaml
```

### Server-Side Validation

Validates against actual cluster API (includes admission controllers):

```bash
# Validate against cluster
make k8s-validate-server

# Or individually
kubectl apply --dry-run=server -f manifests/hello-world-deployment.yaml
```

## Updating the Docker Image

The image is built via Terraform. To deploy a new version:

```bash
# Update image tag in terraform/variables.tf
# Then rebuild and push
make tf-apply

# Update manifest
vi manifests/hello-world-deployment.yaml
# Change image tag to match new version

# Apply update
kubectl apply -f manifests/hello-world-deployment.yaml

# Or use kubectl set image
kubectl set image deployment/hello-world \
  -n hello-world-ns \
  hello-world=802645170184.dkr.ecr.us-east-1.amazonaws.com/hello-world-demo:1.3.3
```

## Deployment Details

### Rolling Update Strategy

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 1
```

### Health Checks

- **Liveness**: HTTP GET / on port 8080 (10s delay, 10s period)
- **Readiness**: HTTP GET / on port 8080 (5s delay, 5s period)

### Volumes

- `nginx-cache` → `/var/cache/nginx` (emptyDir)
- `nginx-run` → `/var/run` (emptyDir)
- `nginx-ssl` → `/etc/nginx/ssl` (emptyDir, for runtime TLS cert generation)

### Service Configuration

```yaml
type: LoadBalancer
annotations:
  service.beta.kubernetes.io/aws-load-balancer-type: nlb
  service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
  service.beta.kubernetes.io/aws-load-balancer-target-type: ip
```

## Monitoring & Debugging

### View Deployment Status

```bash
# Watch pods
kubectl get pods -n hello-world-ns -w

# Deployment status
kubectl rollout status deployment/hello-world -n hello-world-ns

# Describe deployment
make k8s-describe
```

### View Logs

```bash
# Recent logs
make k8s-logs

# Follow logs
kubectl logs -f -n hello-world-ns -l app=hello-world

# Specific pod
kubectl logs -n hello-world-ns <pod-name>
```

### View Events

```bash
# Recent events
make k8s-events

# Or directly
kubectl get events -n hello-world-ns --sort-by='.metadata.creationTimestamp'
```

### Shell Access

```bash
# Open shell in container
make k8s-shell

# Or directly
kubectl exec -it -n hello-world-ns <pod-name> -- sh
```

## Troubleshooting

### Pods CrashLoopBackOff

```bash
# Check pod events
kubectl describe pod <pod-name> -n hello-world-ns

# View logs
kubectl logs <pod-name> -n hello-world-ns

# Previous container logs (if restarted)
kubectl logs <pod-name> -n hello-world-ns --previous
```

### Image Pull Errors

```bash
# Verify image exists in ECR
aws ecr describe-images \
  --repository-name hello-world-demo \
  --region us-east-1

# Check node IAM permissions
kubectl describe node | grep InstanceProfile

# View pod events
kubectl describe pod <pod-name> -n hello-world-ns
```

### LoadBalancer Not Provisioning

```bash
# Check service events
kubectl describe service hello-world-service -n hello-world-ns

# Verify NLB created in AWS
aws elbv2 describe-load-balancers --region us-east-1 | grep hello-world
```

### Certificate Issues

Certificates are generated at container startup by `/usr/local/bin/entrypoint.sh`:

```bash
# Check if certificates exist
kubectl exec -n hello-world-ns <pod-name> -- ls -la /etc/nginx/ssl/

# View certificate details
kubectl exec -n hello-world-ns <pod-name> -- \
  openssl x509 -in /etc/nginx/ssl/nginx.crt -text -noout | grep -A2 "Subject:"

# Check container logs for cert generation
kubectl logs -n hello-world-ns <pod-name> | grep -i certificate
```

### Performance Issues

```bash
# Check resource usage
kubectl top pods -n hello-world-ns

# Check node resources
kubectl top nodes

# View resource limits
kubectl describe deployment hello-world -n hello-world-ns | grep -A5 Limits
```

## Rollback

### Undo Last Deployment

```bash
# Rollback to previous version
make k8s-undo

# Or directly
kubectl rollout undo deployment/hello-world -n hello-world-ns
```

### Rollback to Specific Revision

```bash
# View rollout history
kubectl rollout history deployment/hello-world -n hello-world-ns

# Rollback to specific revision
kubectl rollout undo deployment/hello-world -n hello-world-ns --to-revision=2
```

## Best Practices

1. **Always validate before applying** - Use `make k8s-validate-server`
2. **Use image digests in production** - Pin to specific SHA256 digest
3. **Monitor rollout status** - Watch for errors during deployment
4. **Keep resource limits** - Prevent runaway resource usage
5. **Use health checks** - Ensure containers are actually ready
6. **Enable TLS** - Service supports both HTTP (80) and HTTPS (443)
7. **Review security contexts** - Follow least-privilege principles
8. **Version control manifests** - Track all changes in git

## GitOps Integration

For production environments, consider using GitOps tools:

- **ArgoCD**: Automated sync from git to cluster
- **Flux**: GitOps toolkit for Kubernetes
- **Kustomize**: Environment-specific overlays

## Next Steps

1. ✅ Deploy basic application (this guide)
2. Consider adding:
   - ConfigMaps for configuration
   - Secrets for sensitive data
   - Ingress for HTTP routing
   - HorizontalPodAutoscaler for auto-scaling
   - PodDisruptionBudget for availability
   - NetworkPolicy for traffic control
   - ServiceMonitor for Prometheus metrics

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kustomize](https://kustomize.io/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
