variable "region" {
  description = "AWS region"
  default     = "us-east-1"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  default     = "eks-demo-cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  default     = "1.35"
  type        = string
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  default     = "eks-demo-node-group"
  type        = string
}

variable "hello_world_ns" {
  description = "Name of the Kubernetes namespace"
  default     = "hello-world-ns"
  type        = string
}

variable "monitoring_ns" {
  description = "Name of the Kubernetes namespace"
  default     = "monitoring-ns"
  type        = string
}

variable "vault_ns" {
  description = "Name of the Kubernetes namespace"
  default     = "vault-ns"
  type        = string
}

variable "service" {
  description = "Name of the Kubernetes service"
  default     = "hello-world-service"
  type        = string
}

variable "deployment" {
  description = "Name of the Kubernetes deployment"
  default     = "hello-world"
  type        = string
}

variable "repo_name" {
  description = "ECR repository name"
  default     = "hello-world-demo"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  default     = "1.3.2"
  type        = string
}

variable "tf_state_bucket" {
  description = "S3 bucket for Terraform state"
  default     = "terraform-state-bucket-2727"
  type        = string
}

variable "platforms" {
  description = "Platforms for Docker buildx"
  default     = ["linux/amd64", "linux/arm64"]
  type        = list(string)
}

variable "platform" {
  description = "Platform for Docker build"
  default     = "linux/amd64"
  # default     = "linux/arm64"
  type = string
}

variable "instance_type" {
  description = "EC2 instance type for the EKS node group"
  default     = "t3.small"
  # default     = "t4g.small"
  type = string
}

variable "ami_type" {
  description = "EC2 AMI type for the EKS node group"
  default     = "AL2023_x86_64_STANDARD"
  # default     = "AL2023_ARM_64_STANDARD"
  type = string
}