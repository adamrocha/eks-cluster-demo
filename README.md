# eks-cluster-demo

## Overview

This project provides an example of deploying and managing an Amazon EKS (Elastic Kubernetes Service) cluster using Infrastructure as Code (IaC) tools with a hybrid approach: Terraform manages infrastructure while Kubernetes manifests manage application deployments.

## Features

- **Automated EKS cluster provisioning** with Terraform
- **Kubernetes manifest-based deployments** for applications
- **Blue/Green deployment pattern** for zero-downtime releases
- **Security-hardened IAM policies** with least-privilege access
- **Kustomize support** for environment-specific configurations
- **Validation tools** for manifests before deployment
- **Monitoring stack** with Prometheus and Grafana
- **Automated Docker image builds** and ECR integration
- **Helper scripts** for common operations
- **VPC Flow Logs** and CloudWatch monitoring

## Prerequisites

- AWS account with appropriate permissions
- [Github Actions](https://github.com/features/actions) (optional)
- [Terraform](https://www.terraform.io/) (v1.0+)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (configured with credentials)
- [Docker](https://docs.docker.com/engine/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [jq](https://stedolan.github.io/jq/) (for script operations)
- [helm](https://helm.sh/) (optional, for Prometheus, Grafana, and Vault stacks)
- [eksctl](https://eksctl.io/) (optional)

## GitHub Actions Configuration

The workflow in `.github/workflows/eks-deploy.yml` expects the following GitHub Actions settings.

### Required secrets

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### Required variables

- `AWS_ACCOUNT_ID`
- `AWS_REGION`

### Optional variables (with defaults)

- `EKS_CLUSTER_NAME` (default: `eks-cluster-demo`)
- `NAMESPACE` (default: `hello-world-ns`)
- `REPO_NAME` (default: `hello-world-repo`)
- `IMAGE_TAG` (default: `1.3.2`)

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

## Recommended for production use\*\*

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
make help                # Show all available commands
make check-aws           # Verify AWS credentials
make ansible-inventory   # Show Ansible dynamic inventory (.venv)
make ansible-ssm-ping    # Test EC2 connectivity via AWS SSM
make install-tools       # Install required tools
```

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
```

## Deployment Strategies

This project supports multiple deployment strategies to fit different use cases:

### 1. Rolling Update (Default)

Located in `manifests/` directory. Best for:

- Development environments
- Simple updates with backward compatibility
- Resource-constrained environments

```sh
make k8s-apply          # Deploy with rolling updates
make k8s-restart        # Restart deployment
```

### 2. Blue/Green Deployment

Located in `manifests/blue-green/` directory. Best for:

- Production environments
- Zero-downtime deployments
- Quick rollback capability
- Major version changes

```sh
# Deploy blue/green infrastructure
make bg-deploy

# Check status
make bg-status

# Switch to new version (green)
make bg-switch-green

# Instant rollback if needed
make bg-rollback
```

**Key Benefits:**

- **Zero Downtime** - Traffic switches instantly between versions
- **Fast Rollback** - Revert to previous version in seconds
- **Full Testing** - Test new version before exposing to users
- **Reduced Risk** - Both versions run simultaneously

See [docs/blue-green-deployment.md](docs/blue-green-deployment.md) for detailed guide.

## Project Structure

```text
eks-cluster-demo/
├── .github/                                    # GitHub Actions workflows
│   └── workflows/
│       └── eks-deploy.yml                      # CI/CD deployment pipeline
├── docs/                                       # Documentation
│   ├── kubernetes-deployment-guide.md          # Kubernetes deployment guide
│   ├── terraform-to-manifests-migration.md     # Migration guide
│   ├── blue-green-deployment.md                # Blue/Green deployment guide
│   └── blue-green-quick-reference.md           # Blue/Green quick reference
├── files/                                      # Configuration files
│   ├── lb-controller-policy.json               # AWS Load Balancer Controller IAM policy
│   ├── requirements.txt                        # Python dependencies
│   └── test-terraform-eks.yml                  # Test configuration
├── kube/                                       # Docker build context
│   ├── Dockerfile                              # Container image definition
│   ├── entrypoint.sh                           # Container startup script (TLS cert generation)
│   ├── index.html                              # Application HTML
│   └── nginx.conf                              # Nginx configuration (HTTP + HTTPS)
├── manifests/                                  # Kubernetes YAML manifests
│   ├── hello-world-ns.yaml                     # Namespace definition
│   ├── hello-world-deployment.yaml             # Deployment with security hardening
│   ├── hello-world-service.yaml                # LoadBalancer service
│   ├── kustomization.yaml                      # Kustomize configuration
│   └── blue-green/                             # Blue/Green deployment manifests
│       ├── hello-world-ns.yaml                 # Namespace for blue/green
│       ├── hello-world-deployment-blue.yaml    # Blue deployment
│       ├── hello-world-deployment-green.yaml   # Green deployment
│       ├── hello-world-service.yaml            # Service with version selector
│       └── kustomization.yaml                  # Kustomize for blue/green
├── scripts/                                    # Automation scripts
│   ├── blue-green-switch.sh                    # Blue/Green deployment switcher
│   ├── cleanup_lb.sh                           # Clean up load balancers
│   ├── cleanup_sg.sh                           # Clean up security groups
│   ├── docker-image.sh                         # Build and push Docker images
│   ├── fetch-billing-total.py                  # AWS billing report (Python)
│   ├── fetch-billing-total.sh                  # AWS billing report (Shell)
│   ├── fetch-ec2-instances.sh                  # List EC2 instances
│   ├── fetch-ip.py                             # Get LoadBalancer IP (Python)
│   ├── fetch-ip.sh                             # Get LoadBalancer IP (Shell)
│   ├── fetch-ssm-instances.sh                  # List SSM-managed instances
│   ├── fwd-services.sh                         # Port forwarding for services
│   ├── install-tools.sh                        # Install required tools
│   ├── oidc-provider-url.sh                    # Get OIDC provider URL
│   ├── setup-tfstate-bucket.py                 # Setup Terraform state bucket (Python)
│   ├── setup-tfstate-bucket.sh                 # Setup Terraform state bucket (Shell)
│   ├── start-ec2-instances.sh                  # Start stopped EC2 instances
│   ├── stop-ec2-instances.sh                   # Stop running EC2 instances
│   ├── update-kubeconfig.py                    # Update kubectl config (Python)
│   ├── update-kubeconfig.sh                    # Update kubectl config (Shell)
│   └── update-manifest-image.sh                # Update Docker image in manifests
├── terraform/                                  # Infrastructure as Code
│   ├── backend.tf                              # S3 backend configuration
│   ├── buckets.tf                              # S3 buckets for storage
│   ├── eks.tf                                  # EKS cluster configuration
│   ├── iam.tf                                  # IAM roles and policies
│   ├── keys.tf                                 # KMS encryption keys
│   ├── locals.tf                               # Local variables and Docker build
│   ├── outputs.tf                              # Output values
│   ├── providers.tf                            # AWS, Kubernetes, Docker providers
│   ├── variables.tf                            # Input variables
│   ├── versions.tf                             # Provider version constraints
│   ├── vpc.tf                                  # VPC and networking
│   └── vault.tf                                # HashiCorp Vault (optional)
├── .envrc                                      # direnv environment variables
├── .gitignore                                  # Git ignore patterns
├── Makefile                                    # Build automation and task runner
├── pyproject.toml                              # Python project configuration
├── poetry.lock                                 # Poetry dependency lock file
└── README.md                                   # This file
```

## Documentation

- **[docs/kubernetes-deployment-guide.md](docs/kubernetes-deployment-guide.md)** - Detailed Kubernetes deployment documentation
- **[docs/terraform-to-manifests-migration.md](docs/terraform-to-manifests-migration.md)** - Guide for migrating from Terraform to manifests
- **[docs/blue-green-deployment.md](docs/blue-green-deployment.md)** - Blue/Green deployment pattern guide
- **[docs/blue-green-quick-reference.md](docs/blue-green-quick-reference.md)** - Quick reference for blue/green deployments
- **Makefile** - Run `make help` to see all available commands

## Security Features

- **Least-privilege IAM policies** - All write operations have resource constraints
- **VPC-scoped security groups** - Limited to EKS VPC only
- **KMS encryption** - For EKS secrets, S3 buckets, and CloudWatch logs
- **VPC Flow Logs** - Network traffic monitoring
- **Image scanning** - Automated ECR image vulnerability scanning
- **Read-only root filesystem** - Container security hardening (Temporarily disabled for development)
- **Non-root user** - Containers run as UID 10001 (Temporarily disabled for development)
- **Security contexts** - Drop all capabilities, seccomp profiles

## Monitoring and Logging

- **Prometheus Stack** - Metrics collection and alerting
- **Grafana** - Visualization dashboards
- **CloudWatch Logs** - Centralized logging
- **VPC Flow Logs** - Network traffic analysis
- **SSM Session Manager** - Secure instance access without SSH keys

## Troubleshooting\*\*

```sh
# Verify ECR repository and image
aws ecr describe-images --repository-name hello-world-repo --region us-east-1
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
