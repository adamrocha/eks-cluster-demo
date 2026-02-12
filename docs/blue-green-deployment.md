# Blue/Green Deployment Guide

## Overview

This guide explains how to use the blue/green deployment pattern for the hello-world application in Kubernetes. Blue/green deployment is a release strategy that reduces downtime and risk by running two identical production environments (blue and green), with only one serving live traffic at any time.

## Architecture

### Components

1. **Blue Deployment** (`hello-world-blue`)
   - Runs the current stable version
   - Always ready to receive traffic
   - Located: `manifests/blue-green/hello-world-deployment-blue.yaml`

2. **Green Deployment** (`hello-world-green`)
   - Runs the new version to be tested
   - Deployed alongside blue
   - Located: `manifests/blue-green/hello-world-deployment-green.yaml`

3. **Service** (`hello-world-service`)
   - Routes traffic to either blue or green deployment
   - Controlled by `version` selector label
   - Located: `manifests/blue-green/hello-world-service.yaml`

### How It Works

```text
                     ┌─────────────────┐
                     │  Load Balancer  │
                     └────────┬────────┘
                              │
                     ┌────────▼────────┐
                     │    Service      │
                     │ (version: blue) │
                     └────────┬────────┘
                              │
              ┌───────────────┴───────────────┐
              │                               │
    ┌─────────▼─────────┐         ┌─────────▼─────────┐
    │  Blue Deployment  │         │ Green Deployment  │
    │   (Active)        │         │   (Standby)       │
    │   v1.3.2          │         │   v1.4.0          │
    └───────────────────┘         └───────────────────┘
         3 Replicas                    3 Replicas
```

When switching, only the service selector changes - no pods are restarted.

## Deployment Workflow

### Initial Setup

1. **Deploy the Blue environment** (current version):

```bash
kubectl apply -f manifests/blue-green/hello-world-deployment-blue.yaml
kubectl apply -f manifests/blue-green/hello-world-service.yaml
```

1. **Verify Blue is running**:

```bash
kubectl get pods -n hello-world-ns -l version=blue
kubectl get svc -n hello-world-ns hello-world-service
```

### Deploying a New Version

1. **Update the Green deployment** with the new image version:

```bash
# Edit manifests/blue-green/hello-world-deployment-green.yaml
# Update the image tag to the new version
```

1. **Deploy Green environment**:

```bash
kubectl apply -f manifests/blue-green/hello-world-deployment-green.yaml
```

1. **Wait for Green to be ready**:

```bash
kubectl rollout status deployment/hello-world-green -n hello-world-ns
```

1. **Test the Green deployment** (before switching traffic):

```bash
# Port-forward to test directly
kubectl port-forward -n hello-world-ns deployment/hello-world-green 8080:8080

# Or create a temporary test service
kubectl expose deployment hello-world-green -n hello-world-ns \
  --name=hello-world-green-test --type=LoadBalancer --port=80 --target-port=8080
```

1. **Switch traffic to Green**:

```bash
./scripts/blue-green-switch.sh green
```

1. **Monitor and validate** the Green deployment in production:

```bash
# Check service endpoints
kubectl get endpoints -n hello-world-ns hello-world-service

# Monitor logs
kubectl logs -n hello-world-ns -l version=green --tail=100 -f

# Check metrics/monitoring dashboard
```

1. **Rollback if needed**:

```bash
./scripts/blue-green-switch.sh rollback
```

1. **Once Green is stable**, update Blue for the next deployment cycle:

```bash
# Update blue deployment to match green
kubectl apply -f manifests/blue-green/hello-world-deployment-blue.yaml
```

## Using the Switch Script

The `blue-green-switch.sh` script provides an easy way to manage blue/green deployments.

### Commands

```bash
# Show current status
./scripts/blue-green-switch.sh status

# Switch to blue deployment
./scripts/blue-green-switch.sh blue

# Switch to green deployment
./scripts/blue-green-switch.sh green

# Rollback to previous version
./scripts/blue-green-switch.sh rollback
```

### Example Output

```text
$ ./scripts/blue-green-switch.sh status

=== Blue/Green Deployment Status ===

Current Active Version: blue

Blue Deployment:  READY
Green Deployment: READY

=== Pod Status ===

NAME                                READY   STATUS    VERSION
hello-world-blue-7d4f8c9b5d-abc12   1/1     Running   blue
hello-world-blue-7d4f8c9b5d-def34   1/1     Running   blue
hello-world-blue-7d4f8c9b5d-ghi56   1/1     Running   blue
hello-world-green-8e5f9d0c6e-xyz78  1/1     Running   green
hello-world-green-8e5f9d0c6e-uvw90  1/1     Running   green
hello-world-green-8e5f9d0c6e-rst12  1/1     Running   green
```

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
name: Blue/Green Deploy

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-region: us-east-1
      
      - name: Login to Amazon ECR
        uses: aws-actions/amazon-ecr-login@v1
      
      - name: Build and push image
        run: |
          docker build -t $ECR_REGISTRY/hello-world-demo:${{ github.ref_name }} .
          docker push $ECR_REGISTRY/hello-world-demo:${{ github.ref_name }}
      
      - name: Update green deployment
        run: |
          sed -i 's|image: .*|image: $ECR_REGISTRY/hello-world-demo:${{ github.ref_name }}|' \
            manifests/blue-green/hello-world-deployment-green.yaml
          kubectl apply -f manifests/blue-green/hello-world-deployment-green.yaml
      
      - name: Wait for green to be ready
        run: |
          kubectl rollout status deployment/hello-world-green -n hello-world-ns --timeout=5m
      
      - name: Run smoke tests
        run: |
          # Add your smoke tests here
          ./scripts/smoke-test.sh green
      
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
READY=$(kubectl get deployment $DEPLOYMENT -n hello-world-ns -o jsonpath='{.status.readyReplicas}')
DESIRED=$(kubectl get deployment $DEPLOYMENT -n hello-world-ns -o jsonpath='{.spec.replicas}')

if [ "$READY" != "$DESIRED" ]; then
  echo "Deployment not ready: $READY/$DESIRED"
  exit 1
fi

# Port-forward and test endpoint
kubectl port-forward -n hello-world-ns deployment/$DEPLOYMENT 9090:8080 &
PF_PID=$!
sleep 2

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/)
kill $PF_PID

if [ "$HTTP_CODE" != "200" ]; then
  echo "Health check failed: HTTP $HTTP_CODE"
  exit 1
fi

echo "Health check passed"
exit 0
```

## References

- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Blue/Green Deployment Pattern](https://martinfowler.com/bliki/BlueGreenDeployment.html)
