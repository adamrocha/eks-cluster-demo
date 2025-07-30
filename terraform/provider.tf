provider "aws" {
  shared_credentials_files = ["$HOME/.aws/credentials"]
  shared_config_files      = ["$HOME/.aws/config"]
  profile                  = "prom_infradmin"
  region                   = "us-east-1"
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
    config_path            = "~/.kube/config"
  }
}