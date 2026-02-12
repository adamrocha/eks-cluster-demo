# Deployment Strategy Comparison

| Feature | Rolling Update | Blue/Green | Canary* |
| ------- | -------------- | ---------- | ------- |
| **Zero Downtime** | ✅ | ✅ | ✅ |
| **Rollback Speed** | Medium | ⚡ Instant | Medium |
| **Resource Usage** | ~1.2x | 2x | 1.1-1.5x |
| **Pre-Prod Testing** | ❌ | ✅ Full environment | ✅ Limited traffic |
| **Risk** | Medium | Low | Low |
| **Complexity** | Low | Medium | High |
| **Cost** | Low | High | Medium |
| **Status** | ✅ Available | ✅ Available | *Not implemented |
| **Best For** | Dev/Test | Production | High-risk releases |

## Rolling Update (Default)

Kubernetes gradually replaces pods: creates new pod → waits for ready → terminates old pod → repeats.

**Pros:** Built-in, low resources, simple, automatic health checks  
**Cons:** Mixed versions during update, slower rollback, no pre-validation

**Config:**

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
```

**Use:** Dev/test, backward-compatible changes, cost-sensitive deployments

## Blue/Green Deployment

Two identical environments: deploy to inactive → test thoroughly → switch traffic via service selector → keep old version for instant rollback.

```text
Service (selector: version=blue|green)
        /              \
   Blue (v1.3.2)    Green (v1.4.0)
   [Active]         [Standby]
```

**Pros:** Instant switch/rollback, full pre-testing, no version mixing, zero downtime  
**Cons:** Requires 2x resources, complex DB migrations, higher cost

**Commands:** `make bg-deploy`, `make bg-switch-blue|green`, `make bg-status`

**Use:** Production, major versions, mission-critical apps, when fast rollback essential

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
```

```text
Traffic Distribution:
100% Old  →  95% Old + 5% New
          →  75% Old + 25% New
          →  50% Old + 50% New
          →  100% New
## Canary Deployment*

> **Not yet implemented** - Requires service mesh (Istio/AWS App Mesh) or Argo Rollouts

Gradually shift traffic: 5% → 25% → 50% → 100%. Monitor at each stage, rollback on issues.

**Pros:** Reduced risk, real production validation, limits blast radius  
**Cons:** Requires traffic splitting infrastructure, complex monitoring, longer deployment

**Use:** High-risk releases, sophisticated monitoring available
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

## Quick Decision Guide

| Environment | Recommended Strategy | Why |
| --- | --- | --- |
| Development | Rolling Update | Cost-effective, simple |
| Staging | Blue/Green | Test production process |
| Production | Blue/Green | Zero downtime, fast rollback |
| Production (cost-sensitive) | Rolling Update | Lower resources |

## Migration

**Rolling → Blue/Green:** `make bg-deploy` → `make bg-status` → `make bg-switch-blue`  
**Blue/Green → Rolling:** `make bg-cleanup` → `make k8s-apply`

## Essential Monitoring

- Error rate, response time (p50/p95/p99), pod restarts
- Blue/Green: Active/standby status, traffic verification
- Alerts: Error spikes, crash loops, health check failures

## Best Practices

- Use liveness + readiness probes
- Semantic versioning for images
- Test in lower environments first
- Document rollback procedures
- Monitor actively during deployment

**References:** [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) | [Blue/Green Pattern](https://martinfowler.com/bliki/BlueGreenDeployment.html) | [Canary Deployments](https://martinfowler.com/bliki/CanaryRelease.html)
