# Migration Guide: Terraform to Kubernetes Manifests

**Before:** K8s resources managed via Terraform `kubernetes` provider in `terraform/deploys.tf`  
**After:** Resources managed as YAML in `manifests/`, applied with `kubectl`  
**Note:** EKS cluster (VPC, nodes, IAM) stays in Terraform - only app-level K8s resources migrate

## Migration Steps

```bash
# 1. Update kubeconfig
./scripts/update-kubeconfig.sh

# 2. Update image in manifest
./scripts/update-manifest-image.sh hello-world-demo 1.0.0

# 3. Deploy
make k8s-apply

# 4. Verify
kubectl get all -n hello-world-ns
kubectl get svc hello-world-service -n hello-world-ns \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# 5. Remove from Terraform (optional)
# Comment out kubernetes_* resources in terraform/deploys.tf, then:
cd terraform && terraform apply
# OR remove from state only:
terraform state rm kubernetes_namespace.hello_world_ns
terraform state rm kubernetes_service.hello_world_service  
terraform state rm kubernetes_deployment.hello_world
```

## Key Differences

| Aspect | Terraform | Manifests |
| ------ | --------- | --------- |
| Deploy | `terraform apply` | `kubectl apply -f manifests/` |
| Updates | Update .tf → apply | Update .yaml → apply or `kubectl set image` |
| State | S3 backend | Kubernetes etcd |
| Drift check | `terraform plan` | `kubectl diff` |
| Rollback | Apply previous version | `kubectl rollout undo` |

**Terraform advantages:** Single tool, state tracking, drift detection, variables/modules  
**Manifest advantages:** Faster iterations, native K8s, GitOps friendly, simpler CI/CD

## Recommended Hybrid Approach

- **Terraform:** EKS cluster, VPC, IAM, ECR, S3 (infrastructure)
- **Manifests:** Deployments, services, configmaps, ingresses (applications)

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
   - **CI/CD pipeline** for automated deployments (✅ implemented in GitHub Actions)
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
**Resources exist in both:** `terraform state rm <resource>` OR `terraform destroy -target=<resource>` then redeploy  
**Image pull issues:** Verify ECR image exists, check node IAM permissions  
**LB not creating:** Check service events, verify AWS Load Balancer Controller running

## Rollback to Terraform

1. Uncomment resources in `terraform/deploys.tf`
2. Import: `terraform import kubernetes_namespace.hello_world_ns hello-world-ns` (repeat for deployment, service)
3. Or delete & recreate: `make k8s-delete` → `cd terraform && terraform apply`
