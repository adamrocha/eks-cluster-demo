# Blue/Green Deployment Guide

This project supports blue/green releases using parallel deployments and a Service selector switch.

## Design

- `hello-world-blue`: stable version (usually active)
- `hello-world-green`: candidate version (standby/test)
- `hello-world-service`: routes traffic using `spec.selector.version`

Manifests live in `manifests/blue-green/`.

## When To Use

Use blue/green when you need:

- zero-downtime cutover
- fast rollback
- full validation before exposing users

Prefer rolling updates for lower environments where cost and simplicity matter more.

## Standard Release Flow

1. Deploy blue/green resources.
2. Update the green image.
3. Validate green health and behavior.
4. Switch live traffic to green.
5. Monitor closely.
6. Roll back to blue if needed.

## Commands

### Deploy Blue/Green Baseline

```sh
make bg-deploy
make bg-status
```

### Update Green

```sh
kubectl set image deployment/hello-world-green -n hello-world-ns \
  hello-world=<account>.dkr.ecr.<region>.amazonaws.com/hello-world-repo:<tag>
kubectl rollout status deployment/hello-world-green -n hello-world-ns --timeout=300s
```

### Validate Green Before Switch

```sh
kubectl get pods -n hello-world-ns -l version=green
kubectl logs -n hello-world-ns -l version=green --tail=100
kubectl port-forward -n hello-world-ns deployment/hello-world-green 8080:8080
```

### Switch and Roll Back

```sh
make bg-switch-green
make bg-status

# If needed
make bg-rollback
```

## Operational Checklist

Before switch:

- Green rollout complete and healthy
- Smoke tests pass
- Error rates and latency normal
- Rollback command verified
- Database change is backward compatible

After switch (first 15-60 minutes):

- Watch pod restarts and rollout events
- Watch service endpoints
- Watch error and latency trends

## Database Migration Guidance

Safe for blue/green:

- add nullable columns
- add tables/indexes
- additive schema changes

Risky for single-step blue/green:

- remove/rename columns
- destructive type changes
- drop tables relied on by old code

Recommended multi-phase pattern:

1. Add backward-compatible schema
2. Deploy green with dual-read/dual-write where required
3. Switch traffic
4. Remove old schema in later release

## Troubleshooting

Green does not become ready:

```sh
kubectl describe pods -n hello-world-ns -l version=green
kubectl get events -n hello-world-ns --sort-by=.lastTimestamp | tail -n 30
```

Service routes to wrong version:

```sh
kubectl get svc hello-world-service -n hello-world-ns -o jsonpath='{.spec.selector.version}'
kubectl get endpoints hello-world-service -n hello-world-ns
```

Manual emergency switch:

```sh
kubectl patch service hello-world-service -n hello-world-ns \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

## Cost Notes

Blue/green runs two app environments during validation and cutover windows.

Cost controls:

- keep standby replica count minimal when idle
- use blue/green primarily for production
- use rolling updates for dev/test
