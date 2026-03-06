# eks-cluster-demo

Deploy and operate an Amazon EKS cluster using Terraform for infrastructure and Kubernetes manifests for workloads.

## What This Project Does

- Provisions AWS infrastructure with Terraform (`terraform/`)
- Deploys app workloads with Kubernetes manifests (`manifests/`)
- Supports both rolling updates and blue/green deployments
- Automates bootstrap, provision, deploy, and destroy through GitHub Actions
- Includes operational scripts for cost visibility, cleanup, and cluster access

## Current Architecture

### Design Goals

- Keep infra lifecycle in Terraform
- Keep workload rollout logic in Kubernetes manifests
- Make bootstrap and deployment idempotent for repeated runs
- Allow safe teardown on controlled branch deletion events

### System Components

- `terraform/`: VPC, EKS, IAM, KMS, S3, and related AWS resources
- `manifests/`: Default app deployment, service, namespace, HPA, and network policy
- `manifests/blue-green/`: Parallel blue/green deployment manifests and service switching
- `app/`: Container build context (`Dockerfile`, nginx config, static page)
- `scripts/`: Operational helpers for kubeconfig, billing, bucket management, and cleanup
- `.github/workflows/eks-deploy.yml`: CI/CD automation

### Deployment Model

- Infrastructure: Terraform plan/apply in CI and locally
- Workloads: `kubectl apply -k` via kustomize overlays in CI and locally
- Progressive strategy options:
  - Rolling update (`manifests/`)
  - Blue/green (`manifests/blue-green/`)

## CI/CD Workflow

Workflow file: `.github/workflows/eks-deploy.yml`

### Trigger Events

- `push` to `main`, `stage`, `dev`
- `delete` events (used for controlled destroy flow)

### Job Flow (Push)

1. `terraform-bootstrap`
   - Configures AWS credentials
   - Runs `make tf-bootstrap` (includes `tf-bucket`, `fmt`, `init`, `validate`, `plan`)
2. `provision-infrastructure` (depends on `terraform-bootstrap`)
   - Terraform format check/init/validate/plan/apply
   - Imports ECR repository to state if it exists and is unmanaged
3. `deploy`
   - Updates kubeconfig
   - Applies metrics-server manifests
   - Applies app manifests
   - Updates deployment image
   - Waits for rollout and auto-undoes on rollout failure

### Job Flow (Delete)

1. `check_condition`
   - Allows destroy only if deleted branch starts with `delete/` or `nuke/`
2. `terraform-destroy`
   - Requires `destroy-approval` environment
   - Deletes Kubernetes resources, then runs Terraform destroy

## GitHub Actions Configuration

### Required Secrets

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### Required Variables

- `AWS_ACCOUNT_ID`
- `AWS_REGION`

### Optional Variables (with defaults in workflow)

- `EKS_CLUSTER_NAME` (default: `eks-cluster-demo`)
- `NAMESPACE` (default: `hello-world-ns`)
- `REPO_NAME` (default: `hello-world-repo`)
- `IMAGE_TAG` (default: `1.3.2`)

## Local Operations

### Prerequisites

- AWS CLI authenticated for target account
- Terraform `>= 1.13`
- `kubectl`
- `make`
- Docker (for image work)

### Bootstrap and Provision

```sh
make tf-bootstrap
make tf-apply
```

### Kubernetes Deploy/Validate

```sh
make k8s-validate
make k8s-apply
make k8s-status
```

### Blue/Green Operations

```sh
make bg-deploy
make bg-status
make bg-switch-green
make bg-rollback
```

### Destroy and Cleanup

```sh
make tf-destroy
make nuke_tf_bucket FORCE=1
```

Note: `make tf-destroy` invokes interactive Kubernetes cleanup first.

## Terraform State Bucket Operations

Primary path is `make tf-bucket` (part of `make tf-bootstrap`).

Ad hoc script is also available:

```sh
./scripts/setup-tfstate-bucket.sh
```

Script behavior:

- Creates the bucket if missing
- Applies versioning + SSE encryption on creation
- Supports `ENFORCE_SETTINGS=1` to reconcile settings for existing buckets

Examples:

```sh
ENFORCE_SETTINGS=1 ./scripts/setup-tfstate-bucket.sh
S3_BUCKET=my-tf-state AWS_REGION=us-east-1 ENFORCE_SETTINGS=1 ./scripts/setup-tfstate-bucket.sh
```

## Operational Runbook

### Verify Cluster Access

```sh
aws eks update-kubeconfig --name eks-cluster-demo --region us-east-1
kubectl get nodes
```

### Check Rollout Health

```sh
kubectl get pods -n hello-world-ns
kubectl rollout status deployment/hello-world -n hello-world-ns
kubectl get events -n hello-world-ns --sort-by=.lastTimestamp | tail -n 20
```

### Diagnose Common Issues

Terraform lock/state:

```sh
make tf-clean-lock
```

Load balancer readiness:

```sh
kubectl get svc -n hello-world-ns
kubectl describe svc hello-world-service -n hello-world-ns
```

### Cost and Resource Hygiene

```sh
./scripts/fetch-billing-total.py
./scripts/stop-ec2-instances.sh
./scripts/start-ec2-instances.sh
```

## Repository Layout

```text
.
├── .github/workflows/eks-deploy.yml
├── app/
├── ansible/
├── docs/
├── files/
├── manifests/
│   ├── blue-green/
│   └── metrics-server/
├── scripts/
├── terraform/
├── Makefile
└── pyproject.toml
```

## Additional Documentation

- `docs/kubernetes-deployment-guide.md`
- `docs/blue-green-deployment.md`
- `docs/blue-green-quick-reference.md`
- `docs/deployment-strategy-comparison.md`
- `docs/operations-runbook.md`

## Contributing

1. Create a branch from `main`
2. Validate locally (`make tf-bootstrap`, `make k8s-validate`)
3. Open a pull request
4. Ensure CI succeeds before merge
