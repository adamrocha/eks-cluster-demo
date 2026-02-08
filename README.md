# eks-cluster-demo

## Overview

This project provides an example of deploying and managing an Amazon EKS (Elastic Kubernetes Service) cluster using Infrastructure as Code (IaC) tools with a hybrid approach: Terraform manages infrastructure while Kubernetes manifests manage application deployments.

## Features

- **Automated EKS cluster provisioning** with Terraform
- **Kubernetes manifest-based deployments** for applications
- **Security-hardened IAM policies** with least-privilege access
- **Kustomize support** for environment-specific configurations
- **Validation tools** for manifests before deployment
- **Monitoring stack** with Prometheus and Grafana
- **Automated Docker image builds** and ECR integration
- **Helper scripts** for common operations
- **VPC Flow Logs** and CloudWatch monitoring

## Prerequisites

- AWS account with appropriate permissions
- [Terraform](https://www.terraform.io/) (v1.0+)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (configured with credentials)
- [Docker](https://docs.docker.com/engine/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [jq](https://stedolan.github.io/jq/) (for script operations)
- [helm](https://helm.sh/) (optional, for Prometheus stack)
- [eksctl](https://eksctl.io/) (optional)

## Usage

### Option 1: Terraform-managed (Infrastructure + Applications)

1. **Clone the repository:**

```sh
git clone https://github.com/your-org/eks-cluster-demo.git
cd eks-cluster-demo
```

1. **Configure AWS credentials:**

```sh
aws configure
```

1. **Create the EKS cluster and deploy manifests:**

```sh
make tf-bootstrap
make tf-apply
```

1. **Access the cluster:**

```sh
kubectl get nodes
```

### Option 2: Hybrid Approach (Terraform for Infrastructure, Manifests for Apps)

## Recommended for production use**

1. **Clone the repository:**

```sh
git clone https://github.com/your-org/eks-cluster-demo.git
cd eks-cluster-demo
```

1. **Configure AWS credentials:**

```sh
aws configure
```

1. **Provision EKS cluster with Terraform:**

```sh
make tf-bootstrap
make tf-apply
```

1. **Access the cluster:**

```sh
kubectl get nodes
```

## Quick Reference

### Terraform Commands

```sh
make tf-bootstrap     # Initialize and validate Terraform
make tf-plan          # Preview infrastructure changes
make tf-apply         # Apply infrastructure changes
make tf-destroy       # Destroy all infrastructure (with confirmation)
make tf-output        # Display Terraform outputs
make tf-state         # List Terraform state resources
```

### Kubernetes Manifest Commands

```sh
make k8s-validate         # Validate manifests (client-side)
make k8s-validate-server  # Validate against cluster (server-side)
make k8s-apply            # Deploy all manifests
make k8s-status           # Check deployment status
make k8s-logs             # View application logs
make k8s-describe         # Describe deployment details
make k8s-restart          # Restart deployment
make k8s-delete           # Delete all manifests (with confirmation)
```

### Kustomize Commands

```sh
make k8s-kustomize-validate # Validate kustomize configuration
make k8s-kustomize-apply    # Deploy with kustomize
make k8s-kustomize-diff     # Preview changes
make k8s-kustomize-delete   # Delete resources
```

### Utility Commands

```sh
make help         # Show all available commands
make check-aws    # Verify AWS credentials
make install-tools # Install required tools

### Common Issues

**Pods not starting:**
```sh
kubectl describe pod <pod-name> -n hello-world-ns
kubectl logs <pod-name> -n hello-world-ns
```

**LoadBalancer not provisioning:**

```sh
kubectl describe service hello-world-service -n hello-world-ns
# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
make help         # Show all available commands
make check-aws    # Verify AWS credentials
make install-tools # Install required tools
```

## Project Structure

```text
eks-cluster-demo/
├── Makefile                    # Build automation and task runner
├── README.md                   # This file
├── docs/                      # Documentation
│   ├── kubernetes-deployment-guide.md          # Kubernetes deployment guide
│   └── terraform-to-manifests-migration.md     # Migration guide
├── manifests/                 # Kubernetes YAML manifests
│   ├── kustomization.yaml    # Kustomize configuration
│   ├── hello-world-ns.yaml
│   ├── hello-world-deployment.yaml
│   └── hello-world-service.yaml
├── scripts/                   # Helper scripts
│   ├── update-manifest-image.sh  # Update Docker image in manifests
│   ├── update-kubeconfig.sh      # Configure kubectl access
│   ├── cleanup_lb.sh             # Clean up load balancers
│   ├── cleanup_sg.sh             # Clean up security groups
│   └── docker-image.sh           # Build and push Docker images
├── terraform/                 # Infrastructure as Code
│   ├── backend.tf            # Terraform state backend
│   ├── eks.tf                # EKS cluster configuration
│   ├── iam.tf                # IAM roles and policies
│   ├── vpc.tf                # VPC and networking
│   ├── monitoring.tf         # CloudWatch and logging
│   └── variables.tf          # Variable definitions
└── kube/                      # Docker build context
    ├── Dockerfile
    ├── index.html
    └── nginx.conf
```

## Documentation

- **[docs/kubernetes-deployment-guide.md](docs/kubernetes-deployment-guide.md)** - Detailed Kubernetes deployment documentation
- **[docs/terraform-to-manifests-migration.md](docs/terraform-to-manifests-migration.md)** - Guide for migrating from Terraform to manifests
- **Makefile** - Run `make help` to see all available commands

## Security Features

- **Least-privilege IAM policies** - All write operations have resource constraints
- **VPC-scoped security groups** - Limited to EKS VPC only
- **KMS encryption** - For EKS secrets, S3 buckets, and CloudWatch logs
- **VPC Flow Logs** - Network traffic monitoring
- **Image scanning** - Automated ECR image vulnerability scanning
- **Read-only root filesystem** - Container security hardening
- **Non-root user** - Containers run as UID 10001
- **Security contexts** - Drop all capabilities, seccomp profiles

## Monitoring and Logging

- **Prometheus Stack** - Metrics collection and alerting
- **Grafana** - Visualization dashboards
- **CloudWatch Logs** - Centralized logging
- **VPC Flow Logs** - Network traffic analysis
- **SSM Session Manager** - Secure instance access without SSH keys

## Troubleshooting**

```sh
# Verify ECR repository and image
aws ecr describe-images --repository-name hello-world-demo --region us-east-1
# Check node IAM permissions
kubectl describe node | grep InstanceProfile
```

**Terraform state lock issues:**

```sh
make tf-clean-lock  # Remove stale locks
```

## Cleanup

To delete all resources:

```sh
# Recommended: Delete K8s resources first, then infrastructure
make tf-destroy

# This will:
# 1. Prompt for K8s resource deletion confirmation
# 2. Delete manifests (services, deployments, namespaces)
# 3. Prompt for Terraform infrastructure deletion confirmation
# 4. Destroy EKS cluster, VPC, and all AWS resources
```

**Note:** The destroy process includes confirmations to prevent accidental deletions.

## Cost Optimization

- **Stop EC2 instances** when not in use: `./scripts/stop-ec2-instances.sh`
- **Check billing:** `./scripts/fetch-billing-total.sh`
- **Delete unused resources:** Regularly run `make tf-destroy` for dev/test environments
- **Right-size instances:** Default is `t4g.small` (ARM-based, cost-effective)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Validate with `make k8s-validate` and `terraform validate`
5. Test the deployment
6. Submit a pull request

## License

This project is provided as-is for educational and demonstration purposes.
