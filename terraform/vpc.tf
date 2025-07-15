# Get available AZs
data "aws_availability_zones" "available" {}

# VPC
resource "aws_vpc" "eks" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "eks-vpc"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flow-log/eks"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn
}

resource "aws_flow_log" "eks" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_log.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.eks.id

  iam_role_arn = aws_iam_role.vpc_flow_log.arn
}

# Internet Gateway
resource "aws_internet_gateway" "eks" {
  vpc_id = aws_vpc.eks.id

  tags = {
    Name = "eks-igw"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "eks_public" {
  vpc_id = aws_vpc.eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks.id
  }

  tags = {
    Name = "eks-public-rt"
  }
}

# Subnets (2 public subnets)
resource "aws_subnet" "eks" {
  # checkov:skip=CKV_AWS_130: Publie IP required for EKS
  count                   = 2
  vpc_id                  = aws_vpc.eks.id
  cidr_block              = cidrsubnet(aws_vpc.eks.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "eks-subnet-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

# Associate subnets with route table
resource "aws_route_table_association" "eks_public" {
  count          = 2
  subnet_id      = aws_subnet.eks[count.index].id
  route_table_id = aws_route_table.eks_public.id
}

resource "aws_default_security_group" "restrict_default" {
  vpc_id = aws_vpc.eks.id

  # ingress {
  #   self        = true
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1" # All protocols
  #   cidr_blocks = []
  # }

  # egress {
  #   self        = true
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  tags = {
    Name = "eks-default-sg"
  }
}