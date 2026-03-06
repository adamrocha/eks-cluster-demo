# Operations Runbook

Central runbook for day-2 operations: diagnose quickly, recover safely, and minimize downtime.

## Scope

Use this runbook for:

- CI/CD failures in `.github/workflows/eks-deploy.yml`
- Terraform state/bootstrap issues
- Kubernetes rollout incidents
- Blue/green switch and rollback actions
- Controlled environment teardown

## Quick Triage

1. Confirm AWS identity and region.
2. Confirm cluster access and node readiness.
3. Confirm current deployment and service routing state.
4. Decide rollback vs forward-fix.

```sh
aws sts get-caller-identity
aws configure get region
kubectl get nodes
kubectl get pods -n hello-world-ns
kubectl get svc hello-world-service -n hello-world-ns -o jsonpath='{.spec.selector.version}'
```

## CI/CD Failure Runbook

Workflow: `.github/workflows/eks-deploy.yml`

### `terraform-bootstrap` failed

Checks:

```sh
make check-aws
make tf-bootstrap
```

Typical causes:

- invalid AWS credentials or missing IAM permissions
- Terraform format/validate errors
- state bucket access denied

Recovery:

1. Fix credential/permission issue.
2. Re-run `make tf-bootstrap` locally.
3. Push fix and re-run workflow.

### `provision-infrastructure` failed

Checks:

```sh
terraform -chdir=terraform fmt -check -recursive
terraform -chdir=terraform init
terraform -chdir=terraform validate
terraform -chdir=terraform plan
```

If ECR import conflicts, verify state and repo existence before retry.

### `deploy` failed

Checks:

```sh
kubectl get pods -n hello-world-ns
kubectl describe deployment hello-world -n hello-world-ns
kubectl get events -n hello-world-ns --field-selector type=Warning --sort-by=.lastTimestamp | tail -n 30
```

Recovery:

- If rollout fails, run rollback:

```sh
make k8s-undo
```

## Terraform State and Bootstrap

### Ensure state bucket exists and is configured

Primary path:

```sh
make tf-bucket
```

Ad hoc path:

```sh
./scripts/setup-tfstate-bucket.sh
```

Reconcile bucket settings on existing bucket:

```sh
ENFORCE_SETTINGS=1 ./scripts/setup-tfstate-bucket.sh
```

### Stale lock/state issues

```sh
make tf-clean-lock
```

Then retry:

```sh
make tf-bootstrap
make tf-apply
```

## Kubernetes Incident Runbook

### Pods unhealthy or crash looping

```sh
kubectl get pods -n hello-world-ns
kubectl describe pod <pod-name> -n hello-world-ns
kubectl logs <pod-name> -n hello-world-ns --previous
```

### Service or load balancer issues

```sh
kubectl get svc -n hello-world-ns
kubectl describe svc hello-world-service -n hello-world-ns
kubectl get endpoints hello-world-service -n hello-world-ns
```

### Rollback deployment

```sh
make k8s-undo
kubectl rollout status deployment/hello-world -n hello-world-ns --timeout=300s
```

## Blue/Green Incident Runbook

### Check active color and health

```sh
make bg-status
kubectl get pods -n hello-world-ns -l version=blue
kubectl get pods -n hello-world-ns -l version=green
```

### Switch traffic to green

```sh
make bg-switch-green
```

### Roll back traffic

```sh
make bg-rollback
```

Emergency manual switch to blue:

```sh
kubectl patch service hello-world-service -n hello-world-ns \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

## Controlled Destroy Runbook

### Local/manual destroy

```sh
make tf-destroy
```

### CI destroy via branch delete event

- Delete branch with prefix `delete/` or `nuke/`
- Workflow requires `destroy-approval` environment gate

Safety checks before destroy:

1. Confirm environment/account
2. Confirm no active user traffic
3. Confirm data retention/export requirements

## Cost and Hygiene Tasks

```sh
./scripts/fetch-billing-total.py
./scripts/stop-ec2-instances.sh
./scripts/start-ec2-instances.sh
make nuke_tf_bucket FORCE=1 DRY_RUN=1
```

## Escalation Data To Capture

Collect before escalating:

- failed job name and step from GitHub Actions
- exact command and full error message
- `kubectl get events` output
- deployment revision and rollout history
- Terraform plan/apply error section
