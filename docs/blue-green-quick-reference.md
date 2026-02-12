# Blue/Green Deployment Quick Reference

## Quick Start

### 1. Initial Deployment

```bash
# Deploy both blue and green environments
kubectl apply -k manifests/blue-green/

# Check status
./scripts/blue-green-switch.sh status
```

### 2. Deploy New Version

```bash
# Edit green deployment with new image tag
vim manifests/blue-green/hello-world-deployment-green.yaml

# Apply changes
kubectl apply -f manifests/blue-green/hello-world-deployment-green.yaml

# Wait for ready
kubectl rollout status deployment/hello-world-green -n hello-world-ns

# Test green deployment
kubectl port-forward -n hello-world-ns deployment/hello-world-green 8080:8080

# Switch traffic
./scripts/blue-green-switch.sh green
```

### 3. Rollback

```bash
./scripts/blue-green-switch.sh rollback
```

## Common Commands

| Action | Command |
| ------ | ------- |
| Check status | `./scripts/blue-green-switch.sh status` |
| Switch to blue | `./scripts/blue-green-switch.sh blue` |
| Switch to green | `./scripts/blue-green-switch.sh green` |
| Rollback | `./scripts/blue-green-switch.sh rollback` |
| View pods | `kubectl get pods -n hello-world-ns -l app=hello-world` |
| View service | `kubectl get svc -n hello-world-ns hello-world-service` |
| Check logs (blue) | `kubectl logs -n hello-world-ns -l version=blue --tail=50 -f` |
| Check logs (green) | `kubectl logs -n hello-world-ns -l version=green --tail=50 -f` |
| Describe service | `kubectl describe svc -n hello-world-ns hello-world-service` |
| Get endpoints | `kubectl get endpoints -n hello-world-ns hello-world-service` |

## Deployment Pattern Flow

```text
                    Current State: Blue Active
                            │
                            ▼
                    Deploy Green (new version)
                            │
                            ▼
                    Test Green thoroughly
                            │
                    ┌───────┴───────┐
                    │               │
                    │  Tests Pass?  │
                    │               │
                    └───────┬───────┘
                            │
                ┌───────────┴───────────┐
                │                       │
               YES                      NO
                │                       │
                ▼                       ▼
        Switch to Green          Fix issues or
                │                   rollback
                ▼                       
        Monitor for issues              
                │                       
        ┌───────┴───────┐              
        │               │              
        │   Stable?     │              
        │               │              
        └───────┬───────┘              
                │                      
        ┌───────┴───────┐              
        │               │              
       YES              NO             
        │               │              
        ▼               ▼              
    Update Blue    Rollback to Blue    
```

## Safety Checklist

Before switching to green:

- [ ] Green deployment is fully ready (all replicas running)
- [ ] Health checks are passing
- [ ] Application logs show no errors
- [ ] Smoke tests completed successfully
- [ ] Database migrations (if any) are backward compatible
- [ ] Monitoring/alerts are configured
- [ ] Team is ready to monitor the switch
- [ ] Rollback plan is documented and tested

## Environment Variables

Set these for the switch script:

```bash
export NAMESPACE=hello-world-ns  # Default: hello-world-ns
```

## Troubleshooting Quick Tips

### Pods not starting

```bash
kubectl describe pod -n hello-world-ns -l version=green | grep -A 10 Events
```

### Service not switching

```bash
kubectl patch service hello-world-service -n hello-world-ns \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

### Check current routing

```bash
kubectl get svc hello-world-service -n hello-world-ns \
  -o jsonpath='{.spec.selector.version}' && echo
```

### View all resources

```bash
kubectl get all -n hello-world-ns -l app=hello-world
```
