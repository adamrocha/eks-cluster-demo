# This Terraform configuration sets up the AWS Load Balancer Controller for an EKS cluster.
# https://github.com/kubernetes-sigs/aws-load-balancer-controller/tree/main/helm/aws-load-balancer-controller

# resource "aws_iam_policy" "aws_lb_controller" {
#   name        = "AWSLoadBalancerControllerIAMPolicy"
#   description = "Policy for AWS Load Balancer Controller"
#   policy      = file("../files/lb-controller-policy.json")
# }

# resource "aws_iam_role" "lb_controller" {
#   name               = "AmazonEKSLoadBalancerControllerRole"
#   assume_role_policy = data.aws_iam_policy_document.lb_controller_assume_role.json
# }

# resource "aws_iam_role_policy_attachment" "lb_controller_attach" {
#   role       = aws_iam_role.lb_controller.name
#   policy_arn = aws_iam_policy.aws_lb_controller.arn
# }

# resource "aws_iam_openid_connect_provider" "eks_oidc" {
#   url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.oidc_thumbprint.certificates[0].sha1_fingerprint]
# }

# data "tls_certificate" "oidc_thumbprint" {
#   url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
# }

# data "aws_iam_policy_document" "lb_controller_assume_role" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]

#     principals {
#       type        = "Federated"
#       identifiers = [aws_iam_openid_connect_provider.eks_oidc.arn]
#     }

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub"
#       values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
#     }
#   }
# }

# resource "kubernetes_service_account" "aws_lb_controller" {
#   metadata {
#     name      = "aws-load-balancer-controller"
#     namespace = "kube-system"
#     annotations = {
#       "eks.amazonaws.com/role-arn" = aws_iam_role.lb_controller.arn
#     }
#   }
# }

# resource "helm_release" "aws_lb_controller" {
#   name             = "aws-load-balancer-controller"
#   repository       = "https://aws.github.io/eks-charts"
#   chart            = "aws-load-balancer-controller"
#   namespace        = "kube-system"
#   create_namespace = false
#   timeout          = 600
#   version          = "2.0.0"

#   set {
#     name  = "clusterName"
#     value = var.cluster_name
#   }

#   set {
#     name  = "region"
#     value = var.region
#   }

#   set {
#     name  = "vpcId"
#     value = aws_vpc.eks.id
#   }

#   set {
#     name  = "serviceAccount.create"
#     value = "false"
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = "aws-load-balancer-controller"
#   }
# }
