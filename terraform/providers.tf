provider "aws" {
  default_tags {
    tags = {
      Project     = var.cluster_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "eks-cluster-demo"
    }
  }
}

provider "kubernetes" {
  host  = aws_eks_cluster.eks.endpoint
  token = data.aws_eks_cluster_auth.eks.token
  cluster_ca_certificate = base64decode(
    aws_eks_cluster.eks.certificate_authority[0].data
  )
}

provider "helm" {
  kubernetes = {
    host  = aws_eks_cluster.eks.endpoint
    token = data.aws_eks_cluster_auth.eks.token
    cluster_ca_certificate = base64decode(
      aws_eks_cluster.eks.certificate_authority[0].data
    )
  }
}

provider "docker" {
  registry_auth {
    address  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
    username = "AWS"
    password = data.aws_ecr_authorization_token.token.password
  }
}