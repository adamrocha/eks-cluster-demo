# Blue/Green Quick Reference

## Core Commands

| Action | Command |
| --- | --- |
| Deploy blue/green resources | `make bg-deploy` |
| Show blue/green status | `make bg-status` |
| Switch to blue | `make bg-switch-blue` |
| Switch to green | `make bg-switch-green` |
| Roll back to previous | `make bg-rollback` |
| Cleanup blue/green resources | `make bg-cleanup` |

## Fast Path: Release New Green Version

```sh
kubectl set image deployment/hello-world-green -n hello-world-ns \
  hello-world=<account>.dkr.ecr.<region>.amazonaws.com/hello-world-repo:<tag>
kubectl rollout status deployment/hello-world-green -n hello-world-ns --timeout=300s
kubectl port-forward -n hello-world-ns deployment/hello-world-green 8080:8080
make bg-switch-green
```

## Validate Routing

```sh
kubectl get svc hello-world-service -n hello-world-ns -o jsonpath='{.spec.selector.version}'
kubectl get endpoints hello-world-service -n hello-world-ns
```

## Rollback

```sh
make bg-rollback
```

Manual rollback (emergency):

```sh
kubectl patch service hello-world-service -n hello-world-ns \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

## Quick Troubleshooting

Green not ready:

```sh
kubectl describe pods -n hello-world-ns -l version=green
kubectl get events -n hello-world-ns --sort-by=.lastTimestamp | tail -n 20
```

Unexpected errors after switch:

```sh
kubectl logs -n hello-world-ns -l version=green --tail=200
make bg-rollback
```
