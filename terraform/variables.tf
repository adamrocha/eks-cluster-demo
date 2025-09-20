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

variable "aws_account_id" {
  description = "AWS Account ID"
  default     = "802645170184"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the EKS node group"
  default     = "t4g.small"
  type        = string
}

variable "repo_name" {
  description = "ECR repository name"
  default     = "hello-world-demo"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  default     = "1.2.5"
  type        = string
}

variable "image_digest" {
  description = "Digest of the Docker image to be used in the deployment"
  default     = ""
  type        = string
}

variable "tf_state_bucket" {
  description = "S3 bucket for Terraform state"
  default     = "terraform-state-bucket-2727"
  type        = string
}
