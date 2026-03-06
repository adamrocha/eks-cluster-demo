# Deployment Strategy Comparison

This project currently supports:

- Rolling update (default manifests)
- Blue/green deployment (`manifests/blue-green/`)

Canary is not implemented in this repository.

## Side-by-Side Comparison

| Attribute | Rolling Update | Blue/Green |
| --- | --- | --- |
| Downtime | Zero (when healthy) | Zero |
| Rollback speed | Medium | Fast |
| Resource overhead during release | Low | High |
| Pre-cutover validation | Limited | Full |
| Operational complexity | Low | Medium |
| Cost profile | Lower | Higher |
| Best fit | Dev/test, low-risk changes | Production, high-confidence cutover |

## Rolling Update

### How Rolling Update Works

Kubernetes replaces pods gradually in one deployment.

### Rolling Update Strengths

- simple
- low resource usage
- built-in behavior

### Rolling Update Trade-offs

- old and new versions run at the same time during rollout
- rollback is not instant

### Rolling Update Command Path

```sh
make k8s-validate
make k8s-apply
make k8s-status
```

## Blue/Green

### How Blue/Green Works

Two deployments run in parallel; service selector determines active version.

### Blue/Green Strengths

- instant traffic switch
- instant rollback
- full test of target version before user impact

### Blue/Green Trade-offs

- higher infrastructure/app cost during release windows
- needs disciplined operational runbook
- requires migration planning for schema changes

### Blue/Green Command Path

```sh
make bg-deploy
make bg-status
make bg-switch-green
make bg-rollback
```

## Selection Guide

Choose rolling update when:

- environment is dev/test
- changes are low risk
- cost sensitivity is high

Choose blue/green when:

- environment is production
- rollback speed is critical
- release risk is medium/high

## Migration Between Strategies

Rolling to blue/green:

```sh
make bg-deploy
make bg-status
```

Blue/green back to rolling-only operations:

```sh
make bg-cleanup
make k8s-apply
```

## Monitoring Recommendations

Monitor during any release:

- pod readiness and restart count
- request error rate
- latency (p50/p95/p99)
- deployment events

Blue/green-specific checks:

- active service selector value
- service endpoints point to intended version
