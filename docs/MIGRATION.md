# Migration Guide: Terraform to Kubernetes Manifests

This guide explains how to migrate from Terraform-managed Kubernetes resources to direct YAML manifests.

## Overview

**Before:** Kubernetes resources (namespace, deployment, service) were managed by Terraform via the `kubernetes` provider in `terraform/deploys.tf`.

**After:** Resources are now managed as YAML manifests in the `manifests/` directory and applied directly with `kubectl`.

**Note:** The EKS cluster itself (VPC, nodes, IAM roles, etc.) remains managed by Terraform. Only the application-level Kubernetes resources are being migrated.

## What Changed

### Files Created/Updated

1. **`manifests/hello-world-ns.yaml`** - Already existed, no changes needed
2. **`manifests/hello-world-deployment.yaml`** - Updated to match Terraform configuration
3. **`manifests/hello-world-service.yaml`** - Updated with all annotations from Terraform
4. **`manifests/kustomization.yaml`** - New file for kustomize support
5. **`manifests/README.md`** - New documentation
6. **`scripts/update-manifest-image.sh`** - New helper script
7. **`Makefile`** - Added k8s-* targets for manifest management

### Files to Modify (Optional)

- **`terraform/deploys.tf`** - Comment out or remove `kubernetes_*` resources after migration

## Migration Steps

### Step 1: Verify Prerequisites

```bash
# Ensure kubeconfig is updated
./scripts/update-kubeconfig.sh

# Verify cluster access
kubectl get nodes

# Check current Terraform-managed resources (if any)
kubectl get all -n hello-world-ns
```

### Step 2: Update Image Reference

The manifest uses a placeholder image. Update it with your actual ECR image:

```bash
# Option 1: Use the helper script (recommended)
./scripts/update-manifest-image.sh hello-world-demo 1.3.0

# Option 2: Manually edit manifests/hello-world-deployment.yaml
# Change the image line to your ECR image with digest
```

### Step 3: Deploy Using Manifests

```bash
# Deploy all resources
make k8s-apply

# Or use kustomize
make k8s-kustomize-apply

# Check status
make k8s-status
```

### Step 4: Verify Deployment

```bash
# Check pods are running
kubectl get pods -n hello-world-ns

# Check service is created
kubectl get svc -n hello-world-ns

# Get LoadBalancer URL
kubectl get svc hello-world-service -n hello-world-ns \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Step 5: Remove from Terraform (Optional)

If you want to fully remove the Kubernetes resources from Terraform:

#### Option A: Comment Out (Recommended)

Edit `terraform/deploys.tf` and comment out the three resources:

- `kubernetes_namespace.hello_world_ns`
- `kubernetes_service.hello_world_service`
- `kubernetes_deployment.hello_world`

Then run:

```bash
cd terraform
terraform plan  # Review changes
terraform apply # Update state to remove resources
```

#### Option B: Remove from State Only

Keep the resources running but remove from Terraform state:

```bash
cd terraform
terraform state rm kubernetes_namespace.hello_world_ns
terraform state rm kubernetes_service.hello_world_service
terraform state rm kubernetes_deployment.hello_world
```

## Key Differences

### 1. Image Management

**Terraform:**

```hcl
image = "${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.repo_name}:${var.image_tag}@${data.external.image_digest.result["digest"]}"
```

**Manifests:**

```yaml
image: 802645170184.dkr.ecr.us-east-1.amazonaws.com/hello-world-demo:1.3.0
```

You need to manually update the image or use the helper script.

### 2. Deployment Process

**Terraform:**

```bash
cd terraform
terraform plan
terraform apply
```

**Manifests:**

```bash
make k8s-apply
# or
kubectl apply -f manifests/
```

### 3. Rolling Updates

**Terraform:**

```bash
# Update variables.tf or deploys.tf
terraform apply
```

**Manifests:**

```bash
# Update manifest files
kubectl apply -f manifests/hello-world-deployment.yaml
# or
kubectl set image deployment/hello-world \
  hello-world=<new-image> -n hello-world-ns
```

### 4. State Management

| Aspect | Terraform | Manifests |
| ------ | --------- | --------- |
| State storage | S3 backend | Kubernetes etcd |
| Drift detection | `terraform plan` | `kubectl diff` |
| Rollback | `terraform apply` (previous version) | `kubectl rollout undo` |
| History | Terraform state versions | Deployment revision history |

## Advantages of Manifests

1. **Faster iterations** - No plan/apply cycle
2. **Native Kubernetes** - Direct kubectl commands
3. **GitOps friendly** - Easier integration with ArgoCD/Flux
4. **Simpler CI/CD** - No Terraform state management needed
5. **Standard tooling** - Uses kubectl, kustomize, helm

## Advantages of Terraform

1. **Infrastructure + App** - Single tool for everything
2. **State tracking** - Explicit state management
3. **Variables/Modules** - Better templating and reusability
4. **Dependencies** - Explicit resource dependencies
5. **Drift detection** - Built-in plan command

## Hybrid Approach (Recommended)

Keep the best of both worlds:

- **Terraform manages:** EKS cluster, VPC, IAM roles, ECR, S3 buckets
- **Manifests manage:** Deployments, services, configmaps, ingresses

This separation provides:

- Infrastructure stability (Terraform)
- Application agility (manifests)
- Clear separation of concerns

## Troubleshooting

### Resources already exist

If Terraform resources are still present:

```bash
# Check what Terraform knows about
cd terraform
terraform state list | grep kubernetes

# Option 1: Let kubectl take over (resources keep running)
terraform state rm <resource-name>

# Option 2: Destroy and recreate
terraform destroy -target=<resource-name>
make k8s-apply
```

### Image not pulling

```bash
# Verify image exists in ECR
aws ecr describe-images \
  --repository-name hello-world-demo \
  --region us-east-1

# Check node IAM permissions
kubectl describe node | grep InstanceProfile
```

### Service not creating LoadBalancer

```bash
# Check service events
kubectl describe svc hello-world-service -n hello-world-ns

# Check AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer-controller
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

## Next Steps

1. ✅ Migrate to manifests (this guide)
2. Consider adding:
   - **Helm charts** for better templating
   - **ArgoCD** for GitOps workflows
   - **Kustomize overlays** for multi-environment configs
   - **CI/CD pipeline** for automated deployments
   - **ConfigMaps/Secrets** for configuration management

## Rollback Plan

If you need to revert to Terraform management:

1. Uncomment resources in `terraform/deploys.tf`
2. Import existing resources:

   ```bash
   cd terraform
   terraform import kubernetes_namespace.hello_world_ns hello-world-ns
   terraform import kubernetes_deployment.hello_world hello-world-ns/hello-world
   terraform import kubernetes_service.hello_world_service hello-world-ns/hello-world-service
   ```

3. Or delete and let Terraform recreate:

   ```bash
   make k8s-delete
   cd terraform && terraform apply
   ```

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize](https://kustomize.io/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
