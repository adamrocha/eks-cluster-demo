# eks-cluster-demo

## Overview

This project provides an example of deploying and managing an Amazon EKS (Elastic Kubernetes Service) cluster using Infrastructure as Code (IaC) tools.

## Features

- Automated EKS cluster provisioning
- Deployable using Github Actions
- Integration with AWS CLI and kubectl
- Example Kubernetes manifests (Deployments, Services, etc.)
- Development Vault Deployment
- Prometheus Monitoring Stack Deployment
- Scripts for docker image generation and upload to ECR (Elastic Container Registry)

## Tooling

- AWS account with appropriate permissions
- [Github Actions](https://docs.github.com/en/actions)
- [terraform](https://www.terraform.io/)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Docker](https://docs.docker.com/engine/install/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [eksctl](https://eksctl.io/) (optional)
- [helm](https://helm.sh/)

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

1. **Update kubeconfig:**

```sh
./scripts/update-kubeconfig.sh
```

1. **Deploy applications using manifests:**

```sh
# Update the Docker image reference first
./scripts/update-manifest-image.sh hello-world-demo 1.2.5
# Validate manifests before deploying
make k8s-validate
# Deploy using kubectl
make k8s-apply

# Or deploy using kustomize
make k8s-kustomize-apply

# Check deployment status
make k8s-status
```

See [manifests/README.md](manifests/README.md) for detailed manifest documentation and [MIGRATION.md](MIGRATION.md) for migration guide.

## Quick Reference

### Terraform Commands

```sh
make tf-bootstrap    # Initialize and validate Terraform
make tf-plan         # Preview infrastructure changes
make tf-apply        # Apply infrastructure changes
make tf-destroy      # Destroy all infrastructure
```

### Kubernetes Manifest Commands

```sh
make k8s-validate    # Validate manifests (client-side)
make k8s-apply       # Deploy all manifests
make k8s-status      # Check deployment status
make k8s-logs        # View application logs
make k8s-restart     # Restart deployment
make k8s-delete      # Delete all manifests
```

### Kustomize Commands

```sh
make k8s-kustomize-validate # Validate kustomize config
make k8s-kustomize-apply    # Deploy with kustomize
make k8s-kustomize-diff     # Preview changes
make k8s-kustomize-delete   # Delete resources
```

## Tools Used

- **Terraform**: AWS infrastructure provisioning.
- **AWS CLI**: Interface for managing AWS resources.
- **helm**: Kubernetes package manager.
- **eksctl**: Simplifies EKS cluster creation and management.
- **kubectl**: Command-line tool for interacting with Kubernetes clusters.

## Cleanup

To delete the EKS cluster and associated resources:

```sh
make tf-destroy
```
