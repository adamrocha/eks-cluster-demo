data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

# data "external" "my_ip" {
#   program = ["bash", "../scripts/fetch-ip.sh"]
# }

# trunk-ignore(checkov/CKV_AWS_38)
# trunk-ignore(checkov/CKV_AWS_39)
resource "aws_eks_cluster" "eks" {
  name = var.cluster_name
  # version  = "1.32"
  role_arn = aws_iam_role.eks_cluster.arn

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  vpc_config {
    subnet_ids              = aws_subnet.public[*].id
    endpoint_public_access  = true
    endpoint_private_access = true
    # public_access_cidrs     = ["${data.external.my_ip.result.ip}/32"]
  }

  kubernetes_network_config {
    service_ipv4_cidr = "172.31.0.0/16"
  }

  upgrade_policy {
    support_type = "STANDARD"
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks_secrets.arn
    }
  }

  depends_on = [
    aws_vpc.eks,
    aws_kms_key.eks_secrets
  ]
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.node_group_name
  # version         = "1.32"
  node_role_arn = aws_iam_role.eks_nodes.arn
  subnet_ids    = aws_subnet.public[*].id

  ami_type       = var.ami_type
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = [var.instance_type]

  scaling_config {
    min_size     = 1
    desired_size = 2
    max_size     = 4
  }

  update_config {
    max_unavailable = 1 # max_unavailable_percentage = 25
  }

  depends_on = [
    aws_eks_cluster.eks,
    aws_internet_gateway.eks
  ]
}
