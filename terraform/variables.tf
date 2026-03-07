variable "region" {
  description = "AWS region"
  default     = "us-east-1"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  default     = "eks-cluster-demo"
  type        = string
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  default     = "eks-demo-node-group"
  type        = string
}

variable "repo_name" {
  description = "ECR repository name"
  default     = "hello-world-repo"
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

variable "ami_type" {
  description = "EC2 AMI type for the EKS node group"
  # default     = "AL2023_x86_64_STANDARD"
  default = "AL2023_ARM_64_STANDARD"
  type    = string
}

variable "instance_type" {
  description = "EC2 instance type for the EKS node group"
  # default     = "t3.small"
  default = "t4g.small"
  type    = string
}

# trunk-ignore(tflint/terraform_unused_declarations)
variable "monitoring_ns" {
  description = "Name of the Kubernetes namespace"
  default     = "monitoring-ns"
  type        = string
}

# trunk-ignore(tflint/terraform_unused_declarations)
variable "vault_ns" {
  description = "Name of the Kubernetes namespace"
  default     = "vault-ns"
  type        = string
}