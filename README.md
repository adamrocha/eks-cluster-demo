# eks-cluster-demo
## Overview

This project provides an example of deploying and managing an Amazon EKS (Elastic Kubernetes Service) cluster using Infrastructure as Code (IaC) tools.

## Features

- Automated EKS cluster provisioning
- Integration with AWS CLI and kubectl
- Sample Kubernetes manifests for application deployment
- Development Vault Deployment
- Prometheus Monitoring Stack 

## Prerequisites

- AWS account with appropriate permissions
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [eksctl](https://eksctl.io/) (optional)
- [helm](https://helm.sh/)
- [terraform](https://www.terraform.io/)

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
    make tf-bucket
    make tf-tasks
    make tf-apply
    ```

4. **Deploy workloads on the fly (optional):**
    ```sh
    kubectl apply -f manifests/
    ```

5. **Access the cluster:**
    ```sh
    kubectl get nodes
    ```

## Tools Used

- **Terraform**: AWS infrastructure provisioning.
- **AWS CLI**: Interface for managing AWS resources.
- **eksctl**: Simplifies EKS cluster creation and management.
- **kubectl**: Command-line tool for interacting with Kubernetes clusters.

## Cleanup

To delete the EKS cluster and associated resources:
```sh
    make tf-destroy
```

