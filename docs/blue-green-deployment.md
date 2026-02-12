# Blue/Green Deployment Guide

Two identical production environments where only one serves live traffic. Switch by changing service selector - instant rollback, zero downtime.

## Components

- **Blue** (`hello-world-blue`) - Current stable version
- **Green** (`hello-world-green`) - New version for testing  
- **Service** - Routes traffic via `version` selector label

Files: `manifests/blue-green/`

## Workflow

1. Update green deployment image → `kubectl apply -f manifests/blue-green/hello-world-deployment-green.yaml`
2. Wait for ready → `kubectl rollout status deployment/hello-world-green -n hello-world-ns`
3. Test green → `kubectl port-forward -n hello-world-ns deployment/hello-world-green 8080:8080`
4. Switch traffic → `./scripts/blue-green-switch.sh green`
5. Monitor logs → `kubectl logs -n hello-world-ns -l version=green -f`
6. Rollback if needed → `./scripts/blue-green-switch.sh rollback`

**Commands:** `./scripts/blue-green-switch.sh {status|blue|green|rollback}`

## Best Practices

### 1. Pre-Deployment Checks

- Ensure the new version image is built and pushed to ECR
- Verify database migrations are compatible with both versions
- Review resource requirements and update if needed

### 2. Testing Before Switch

- Always test the green deployment before switching traffic
- Use port-forwarding or a temporary test service
- Run smoke tests and health checks
- Perform load testing if possible

### 3. Gradual Traffic Shift (Advanced)

For more cautious releases, consider using a service mesh (Istio/Linkerd) or AWS App Mesh for gradual traffic shifting:

- Start with 10% traffic to green
- Gradually increase: 25% → 50% → 75% → 100%
- Monitor metrics at each step

### 4. Monitoring

- Set up alerts for:
  - Pod crash loops
  - Increased error rates
  - High latency
  - Resource exhaustion
- Monitor CloudWatch metrics during and after switch

### 5. Rollback Strategy

- Keep blue deployment running for quick rollback
- Document rollback procedures
- Set a time window for rollback decision (e.g., 1 hour)
- Use the rollback command at first sign of issues

### 6. Cleanup

- After green is stable (24-48 hours), update blue to match green
- This keeps both environments synchronized
- Never delete the inactive deployment

## Database Migrations

Blue/green deployments with database changes require special care:

### Compatible Changes (Safe for Blue/Green)

- Adding new tables
- Adding nullable columns
- Adding indexes
- Expanding column sizes
- Adding new views

### Incompatible Changes (Require Multi-Phase Deployment)

- Removing columns
- Renaming columns
- Changing column types
- Removing tables

### Multi-Phase Migration Strategy

1. **Phase 1**: Make schema changes backward compatible
   - Add new column (keep old column)
   - Deploy green with code that writes to both columns

2. **Phase 2**: Switch traffic to green
   - Verify green works correctly

3. **Phase 3**: Cleanup
   - Update blue to match green
   - Remove old column in next release

## Troubleshooting

### Green Deployment Won't Start

```bash
# Check pod events
kubectl describe pod -n hello-world-ns -l version=green

# Check image pull
kubectl get events -n hello-world-ns --sort-by='.lastTimestamp'

# Verify image exists in ECR
aws ecr describe-images --repository-name hello-world-demo --image-ids imageTag=1.4.0
```

### Service Not Routing Correctly

```bash
# Verify service selector
kubectl get svc hello-world-service -n hello-world-ns -o yaml | grep -A 2 selector

# Check endpoints
kubectl get endpoints hello-world-service -n hello-world-ns -o yaml
```

### Rollback Not Working

```bash
# Manually patch the service
kubectl patch service hello-world-service -n hello-world-ns \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

## CI/CD Integration

### Example GitHub Actions Workflow

```yaml
- **Pre-deploy:** Verify image in ECR, ensure DB migrations backward-compatible
- **Test first:** Always test green before switching (port-forward, smoke tests)
- **Monitor:** Alert on pod crashes, errors, latency, resource issues
- **Rollback window:** Set decision window (e.g., 1 hour), rollback at first sign of issues
- **Keep synced:** After 24-48h stability, update blue to match green
- **Never delete inactive:** Keep for instant rollback capability
      - name: Switch to green (manual approval recommended)
        run: |
          ./scripts/blue-green-switch.sh green
```

## Comparison with Rolling Updates

| Aspect | Blue/Green | Rolling Update |
| ------ | ---------- | -------------- |
| Downtime | Zero | Zero |
| Resource Usage | 2x during deployment | ~1.2x during deployment |
| Rollback Speed | Instant | Gradual |
| Testing | Full environment before switch | Progressive |
| Risk | Lower | Medium |
| Complexity | Higher | Lower |
| Database Migrations | Requires careful planning | More flexible |

## Cost Considerations

- Blue/green requires double the resources during deployment
- Both environments run continuously
- For cost optimization:
  - Scale down the inactive environment to 1 replica
  - Use spot instances for the inactive environment
  - Consider using this pattern only for production
  - Use rolling updates for non-production environments

## Advanced: Automated Health Checks

Create a health check script to validate deployment before switching:

```bash
#!/bin/bash
# scripts/health-check.sh

VERSION=$1
DEPLOYMENT="hello-world-${VERSION}"

# Check deployment is ready
**Safe:** Add tables/columns (nullable), add indexes, expand columns  
**Unsafe:** Remove/rename columns, change types, remove tables

**Multi-phase strategy:** Add new column (keep old) → Deploy green writing to both → Switch → Update blue →WS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Blue/Green Deployment Pattern](https://martinfowler.com/bliki/BlueGreenDeployment.html)
**Pods not starting:** `kubectl describe pod -n hello-world-ns -l version=green | grep Events`  
**Wrong routing:** `kubectl get svc hello-world-service -n hello-world-ns -o yaml | grep -A2 selector`  
**Manual rollback:** `kubectl patch svc hello-world-service -n hello-world-ns -p '{"spec":{"selector":{"version":"blue"}}}'`

## Cost Optimization

Requires 2x resources. **Reduce:** Scale inactive to 1 replica, use spot instances, reserve for production only
