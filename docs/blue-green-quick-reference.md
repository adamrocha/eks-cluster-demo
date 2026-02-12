# Blue/Green Quick Reference

## Deploy New Version

```bash
# Edit green with new image
vim manifests/blue-green/hello-world-deployment-green.yaml

# Deploy & wait
kubectl apply -f manifests/blue-green/hello-world-deployment-green.yaml
kubectl rollout status deployment/hello-world-green -n hello-world-ns

# Test locally
kubectl port-forward -n hello-world-ns deployment/hello-world-green 8080:8080

# Switch
./scripts/blue-green-switch.sh green

# Rollback if needed
./scripts/blue-green-switch.sh rollback
```

## Commands

| Action | Command |
| ------ | ------- |
| Status | `./scripts/blue-green-switch.sh status` |
| Switch to blue/green | `./scripts/blue-green-switch.sh {blue\|green}` |
| Rollback | `./scripts/blue-green-switch.sh rollback` |
| View pods | `kubectl get pods -n hello-world-ns` |
| Logs (blue/green) | `kubectl logs -n hello-world-ns -l version={blue\|green} -f` |
| Current routing | `kubectl get svc hello-world-service -n hello-world-ns -o jsonpath='{.spec.selector.version}'` |

## Deployment Pattern Flow

```text
                    Current State: Blue Active
   Pre-Switch Checklist

- [ ] Green deployment ready (all replicas running)
- [ ] Health checks passing, no errors in logs
- [ ] Smoke tests completed
- [ ] DB migrations backward compatible
- [ ] Monitoring/alerts configured
- [ ] Rollback plan ready

## Troubleshooting

**Pods failing:** `kubectl describe pod -n hello-world-ns -l version=green | grep Events`  
**Manual switch:** `kubectl patch svc hello-world-service -n hello-world-ns -p '{"spec":{"selector":{"version":"blue"}}}'
