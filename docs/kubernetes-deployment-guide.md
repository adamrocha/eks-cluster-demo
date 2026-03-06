# Kubernetes Deployment Guide

Deploy and operate the `hello-world` workload on EKS using manifests under `manifests/`.

## Design Overview

- Namespace: `hello-world-ns`
- Workload: `Deployment/hello-world`
- Service: `Service/hello-world-service` (LoadBalancer)
- Autoscaling: `hello-world-hpa.yaml`
- Network controls: `hello-world-networkpolicy.yaml`
- Metrics support: `manifests/metrics-server/`

## Prerequisites

- EKS cluster exists and is reachable
- AWS credentials are configured
- `kubectl` context points at target cluster

Set kubeconfig:

```sh
aws eks update-kubeconfig --name eks-cluster-demo --region us-east-1
kubectl get nodes
```

## Standard Operations

Validate manifests:

```sh
make k8s-validate
```

Deploy manifests:

```sh
make k8s-apply
```

Check status:

```sh
make k8s-status
```

View logs:

```sh
make k8s-logs
```

Restart deployment:

```sh
make k8s-restart
```

Delete manifests:

```sh
make k8s-delete
```

Preview diff before apply:

```sh
make k8s-kustomize-diff
```

## Updating the Image

Update image on running deployment:

```sh
kubectl set image deployment/hello-world -n hello-world-ns \
  hello-world=<account>.dkr.ecr.<region>.amazonaws.com/hello-world-repo:<tag>
kubectl rollout status deployment/hello-world -n hello-world-ns --timeout=300s
```

## Rollback

Undo last rollout:

```sh
make k8s-undo
```

Direct rollback command:

```sh
kubectl rollout undo deployment/hello-world -n hello-world-ns
```

## Operational Checks

Pods and health:

```sh
kubectl get pods -n hello-world-ns
kubectl describe deployment hello-world -n hello-world-ns
```

Service and load balancer:

```sh
kubectl get svc -n hello-world-ns
kubectl describe svc hello-world-service -n hello-world-ns
```

Recent warning events:

```sh
kubectl get events -n hello-world-ns --field-selector type=Warning --sort-by=.lastTimestamp | tail -n 20
```

## Troubleshooting

CrashLoopBackOff:

```sh
kubectl describe pod <pod-name> -n hello-world-ns
kubectl logs <pod-name> -n hello-world-ns --previous
```

Image pull errors:

```sh
aws ecr describe-images --repository-name hello-world-repo --region us-east-1
kubectl describe pod <pod-name> -n hello-world-ns
```

Metrics/HPA not reporting:

```sh
kubectl get apiservices | grep metrics.k8s.io
kubectl get pods -n kube-system | grep metrics-server
```

## Production Guidance

- Validate before apply
- Use immutable image tags per release
- Watch rollout status for every deployment
- Keep rollback command ready
- Monitor latency/error rate during and after release
