resource "helm_release" "cloudwatch_exporter" {
  depends_on       = [aws_eks_node_group.node_group]
  name             = "prometheus-cloudwatch-exporter"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus-cloudwatch-exporter"
  namespace        = var.monitoring_ns
  create_namespace = true
  timeout          = 600
  skip_crds        = false
  wait             = true
  version          = "0.28.0"
  values = [
    yamlencode({
      serviceAccount = {
        create = true
        name   = "cloudwatch-exporter"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.cloudwatch_exporter.arn
        }
      }
      aws = {
        region = "us-west-2"
      }
      config = <<EOF
region: us-west-2
metrics:
  - aws_namespace: AWS/EC2
    aws_metric_name: CPUUtilization
    aws_dimensions: [InstanceId]
    aws_statistics: [Average]
  - aws_namespace: AWS/ELB
    aws_metric_name: RequestCount
    aws_dimensions: [LoadBalancerName]
    aws_statistics: [Sum]
EOF
    })
  ]
}

resource "aws_iam_policy" "cloudwatch_exporter" {
  name        = "CloudWatchExporterPolicy"
  description = "Allow CloudWatch exporter to read metrics"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "cloudwatch_exporter" {
  name = "cloudwatch-exporter-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.oidc.url, "https://", "")}:sub" = "system:serviceaccount:monitoring:cloudwatch-exporter"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_exporter_attach" {
  role       = aws_iam_role.cloudwatch_exporter.name
  policy_arn = aws_iam_policy.cloudwatch_exporter.arn
}
