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

1. **Clone the repository:**

```sh
git clone https://github.com/your-org/eks-cluster-demo.git
cd eks-cluster-demo
```

2. **Configure AWS credentials:**

```sh
aws configure
```

3. **Create the EKS cluster and deploy manifests:**

```sh
make tf-bootstrap
make tf-apply
```

4. **Access the cluster:**

```sh
kubectl get nodes
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
