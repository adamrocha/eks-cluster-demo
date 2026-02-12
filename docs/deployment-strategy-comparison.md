# Deployment Strategy Comparison

## Overview

This document compares different Kubernetes deployment strategies available in this project.

## Strategy Comparison Table

| Feature | Rolling Update | Blue/Green | Canary* |
| ------- | -------------- | ---------- | ------- |
| **Zero Downtime** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Rollback Speed** | Medium (gradual) | ⚡ Instant | Medium |
| **Resource Usage** | Low (~1.2x) | High (2x) | Medium (1.1-1.5x) |
| **Testing Before Production** | ❌ No | ✅ Yes (full environment) | ✅ Yes (limited traffic) |
| **Risk Level** | Medium | 🟢 Low | 🟢 Low |
| **Complexity** | 🟢 Low | Medium | High |
| **Database Migration Support** | Good | Fair (requires planning) | Fair |
| **Cost** | 🟢 Low | High | Medium |
| **Production Ready** | ✅ Yes | ✅ Yes | *Not yet implemented |
| **Best For** | Dev/Test | Production | High-risk releases |

## Rolling Update (Default)

### How It Works

Kubernetes gradually replaces old pods with new ones:

1. Create new pod with updated version
2. Wait for new pod to be ready
3. Terminate one old pod
4. Repeat until all pods are updated

### Architecture

```text
Old Version (v1.3.2)    →    New Version (v1.4.0)
[Pod1] [Pod2] [Pod3]         [Pod1'] [Pod2'] [Pod3']
   ↓      ↓      ↓               ↓       ↓       ↓
   ✓      →      →               →       →       ✓
   ✓      ✓      →               →       ✓       ✓
   ✓      ✓      ✓               ✓       ✓       ✓
```

### Rolling Update Pros

- ✅ Built into Kubernetes
- ✅ Low resource usage
- ✅ Simple configuration
- ✅ Automatic health checking
- ✅ No additional infrastructure needed

### Rolling Update Cons

- ❌ Both versions run during update
- ❌ Slower rollback
- ❌ No pre-production validation
- ❌ Cannot test new version before exposure

### Configuration

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1  # Max pods down during update
      maxSurge: 1        # Max extra pods during update
```

### Use Cases

- Development environments
- Backward-compatible changes
- Microservices with many instances
- Cost-sensitive deployments

---

## Blue/Green Deployment

### How Blue/Green Works

Two identical production environments (blue and green):

1. Blue runs current version (production)
2. Deploy new version to green
3. Test green thoroughly
4. Switch traffic from blue to green
5. Keep blue running for quick rollback

### Blue/Green Architecture

```text
                   LoadBalancer
                        |
                   Service (selector: version)
                   /              \
           Blue (v1.3.2)      Green (v1.4.0)
           [Active]           [Standby]
           
           After switch:
           
           Blue (v1.3.2)      Green (v1.4.0)
           [Standby]          [Active]
```

### Blue/Green Pros

- ✅ Instant traffic switch
- ✅ Zero downtime
- ✅ Full environment testing
- ✅ Instant rollback (change selector back)
- ✅ No version mixing
- ✅ Production validation before exposure

### Blue/Green Cons

- ❌ Requires 2x resources
- ❌ More complex setup
- ❌ Database migrations need careful planning
- ❌ Higher costs during deployment

### Configuration Files

Located in `manifests/blue-green/`:

- `hello-world-deployment-blue.yaml` - Blue environment
- `hello-world-deployment-green.yaml` - Green environment  
- `hello-world-service.yaml` - Service with version selector

### Blue/Green Use Cases

- Production environments
- Major version changes
- Mission-critical applications
- When fast rollback is essential
- Testing new features in production-like environment

---

## Canary Deployment*

### How Canary Works

> **Note:** Not yet implemented in this project

Gradually shift traffic from old to new version:

1. Deploy new version alongside old
2. Route small percentage to new version (e.g., 5%)
3. Monitor metrics
4. Gradually increase traffic (10% → 25% → 50% → 100%)
5. Roll back at any sign of issues

### Canary Architecture

```text
                   LoadBalancer
                        |
                   Service (selector: version)
                   /              \
           Old Version (v1.3.2)  New Version (v1.4.0)
           [95% Traffic]         [5% Traffic]
           
           Gradually shift traffic:
           
           Old Version (v1.3.2)  New Version (v1.4.0)
           [75% Traffic]         [25% Traffic]
           
           Old Version (v1.3.2)  New Version (v1.4.0)
           [50% Traffic]         [50% Traffic]
           
           Old Version (v1.3.2)  New Version (v1.4.0)
           [0% Traffic]          [100% Traffic]
```text
Traffic Distribution:
100% Old  →  95% Old + 5% New
          →  75% Old + 25% New
          →  50% Old + 50% New
          →  100% New
```

### Canary Advantages

- ✅ Gradual rollout reduces risk
- ✅ Real production validation
- ✅ Can limit blast radius
- ✅ Early issue detection

### Canary Disadvantages

- ❌ Requires traffic splitting (Istio/Linkerd/AWS App Mesh)
- ❌ Complex monitoring needed
- ❌ Longer deployment time
- ❌ More infrastructure complexity

### Implementation Options

To implement canary deployments, consider:

1. **Istio Service Mesh** - VirtualService with traffic weights
2. **AWS App Mesh** - Weighted routing
3. **Flagger** - Progressive delivery automation
4. **Argo Rollouts** - Advanced deployment strategies

### Canary Use Cases

- High-risk releases
- User-facing changes
- When A/B testing is valuable
- Applications with sophisticated monitoring

---

## Decision Matrix

### Choose Rolling Update if

- ✅ Working in dev/test environment
- ✅ Resource budget is limited
- ✅ Changes are backward compatible
- ✅ Simpler deployment is preferred

### Choose Blue/Green if

- ✅ Production environment
- ✅ Zero downtime is critical
- ✅ Fast rollback capability needed
- ✅ Can allocate 2x resources
- ✅ Want to test in production environment first

### Choose Canary if

- ✅ Very high-risk changes
- ✅ Have service mesh infrastructure
- ✅ Sophisticated monitoring in place
- ✅ Want gradual rollout
- ❌ **Not yet available in this project**

---

## Cost Analysis

### Rolling Update

```text
Base cost: $X
During deployment: ~$1.2X
After deployment: $X
Total time at elevated cost: 2-5 minutes
```

### Blue/Green

```text
Base cost: $X  
During deployment: $2X (both environments)
After deployment: $X (can keep standby scaled down)
Total time at elevated cost: Duration of validation (hours/days)
```

### Resource Recommendation by Environment

| Environment | Strategy | Reason |
| --- | --- | --- |
| Development | Rolling Update | Cost-effective, simpler |
| Staging | Blue/Green | Test production deployment process |
| Production | Blue/Green | Zero downtime, fast rollback |
| Production (cost-sensitive) | Rolling Update | Lower resource usage |

---

## Migration Path

### From Rolling Update to Blue/Green

1. Review current deployment:

```bash
kubectl get deployment hello-world -n hello-world-ns -o yaml
```

1. Deploy blue/green structure:

```bash
make bg-deploy
```

1. Verify both environments:

```bash
make bg-status
```

1. Switch to new deployment pattern:

```bash
make bg-switch-blue
```

### From Blue/Green to Rolling Update

1. Delete blue/green resources:

```bash
make bg-cleanup
```

1. Deploy standard manifests:

```bash
make k8s-apply
```

---

## Monitoring Recommendations

### Key Metrics to Track

**For All Strategies:**

- Pod restart count
- Error rate
- Response time (p50, p95, p99)
- Request rate
- CPU and memory usage

**Blue/Green Specific:**

- Active environment status
- Inactive environment readiness
- Traffic distribution verification

### Alerting

Set up alerts for:

- Error rate spike during/after deployment
- Pod crash loops
- Health check failures
- Resource exhaustion
- Increased latency

---

## Best Practices

### General

1. Always run health checks (liveness + readiness probes)
2. Use semantic versioning for images
3. Test in lower environments first
4. Document rollback procedures
5. Monitor deployments actively

### Rolling Update Best Practices

- Set appropriate `maxUnavailable` and `maxSurge`
- Use `minReadySeconds` to slow down rollout
- Implement comprehensive health checks

### Blue/Green Best Practices

- Keep both environments synchronized
- Test green thoroughly before switching
- Document database migration strategy
- Have rollback plan ready
- Monitor both environments

---

## References

- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/)
- [Blue/Green Pattern by Martin Fowler](https://martinfowler.com/bliki/BlueGreenDeployment.html)
- [Project Blue/Green Guide](blue-green-deployment.md)
