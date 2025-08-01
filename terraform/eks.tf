data "aws_caller_identity" "current" {}

data "google_client_config" "default" {}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

data "external" "my_ip" {
  program = ["bash", "${path.module}./scripts/get_my_ip.sh"]
}

resource "aws_eks_cluster" "eks" {
  # checkov:skip=CKV_AWS_39: Pubic access to the EKS cluster is required for this demo

  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = aws_subnet.eks[*].id
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = ["${data.external.my_ip.result.ip}/32"]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks_secrets.arn
    }
  }
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.eks[*].id

  scaling_config {
    desired_size = 4
    min_size     = 2
    max_size     = 6
  }

  # instance_types = ["t3.small"]
  # capacity_type  = "ON_DEMAND"
  # disk_size      = 20
  # ami_type       = "AL2023_x86_64_STANDARD"

  instance_types = [var.instance_type]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  ami_type       = "AL2023_ARM_64_STANDARD"
}
