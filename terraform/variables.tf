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


