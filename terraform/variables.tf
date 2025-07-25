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

variable "namespace" {
  description = "Name of the Kubernetes namespace"
  default     = "hello-world-ns"
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
  default     = "t3.small"
  type        = string
}

variable "repo_name" {
  description = "ECR repository name"
  default     = "hello-world-demo"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  default     = "1.2.0"
  type        = string
}

variable "image_digest" {
  description = "Digest of the Docker image to be used in the deployment"
  default     = "sha256:7d29cd1195c0cb64d67f9aa7ed0fd3de723026566679a9354fbadbb19e2450bd"
  type        = string

}