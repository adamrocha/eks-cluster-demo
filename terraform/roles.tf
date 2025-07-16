resource "aws_iam_role" "vpc_flow_log" {
  name = "eks-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "vpc_flow_log" {
  name = "eks-vpc-flow-log-policy"
  role = aws_iam_role.vpc_flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_log.arn}"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.vpc_flow_log.arn}"
      }
    ]
  })
}

resource "aws_iam_role" "s3_replication" {
  name = "s3-replication-role" # Choose a descriptive name for your IAM role

  # The trust policy that allows S3 to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "s3_replication_policy" {
  name        = "s3-replication-policy" # Choose a descriptive name for your policy
  description = "Policy for S3 bucket replication"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectRetention",
          "s3:GetObjectLegalHold",
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.tf_state.arn,        # Source bucket ARN
          "${aws_s3_bucket.tf_state.arn}/*", # Objects in source bucket
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.tf_state_replica.arn,        # Destination bucket ARN (assuming you have one, adjust as needed)
          "${aws_s3_bucket.tf_state_replica.arn}/*", # Objects in destination bucket
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_replication_attach" {
  role       = aws_iam_role.s3_replication.name
  policy_arn = aws_iam_policy.s3_replication_policy.arn
}