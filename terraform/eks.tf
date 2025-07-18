data "aws_caller_identity" "current" {}

resource "aws_eks_cluster" "eks" {
  # checkov:skip=CKV_AWS_38: This is a demo cluster, not production
  # checkov:skip=CKV_AWS_39: This is a demo cluster, not production
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]

  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = aws_subnet.eks[*].id
    endpoint_public_access  = true
    endpoint_private_access = true
    # public_access_cidrs     = []
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
  depends_on = [
    aws_eks_cluster.eks,
    aws_iam_role_policy_attachment.eks_worker_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_worker_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_worker_AmazonEC2ContainerRegistryReadOnly
  ]

  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.eks[*].id

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.small"]
  capacity_type  = "ON_DEMAND"
  # disk_size      = 20
  # ami_type       = "AL2_x86_64"
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}