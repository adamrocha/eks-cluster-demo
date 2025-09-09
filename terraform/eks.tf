data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

data "external" "my_ip" {
  program = ["bash", "../scripts/fetch-ip.sh"]
}

resource "aws_eks_cluster" "eks" {
  # checkov:skip=CKV_AWS_39: Pubic access to the EKS cluster is required for this demo
  depends_on = [
    aws_vpc.eks
    # null_resource.cleanup_sg
  ]
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = aws_subnet.public[*].id
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = ["0.0.0.0/0"]
    # public_access_cidrs     = ["${data.external.my_ip.result.ip}/32"]
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
  depends_on = [aws_eks_cluster.eks,
    aws_internet_gateway.eks
  ]
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 4
  }

  # instance_types = ["t3.small"]
  # capacity_type  = "ON_DEMAND"
  # disk_size      = 20
  # ami_type       = "AL2023_x86_64_STANDARD"

  instance_types = [var.instance_type]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  ami_type       = "AL2023_ARM_64_STANDARD"

  update_config {
    max_unavailable = 1
    # OR
    # max_unavailable_percentage = 50
  }
}
