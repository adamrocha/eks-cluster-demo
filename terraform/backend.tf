# terraform {
#   backend "s3" {
#     bucket         = "terraform-state-bucket-2727"
#     key            = "envs/dev/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }

# resource "aws_s3_bucket" "tf_state" {
#   # This bucket is used for storing Terraform state files
#   # checkov:skip=CKV_AWS_144: development bucket, not production
#   # checkov:skip=CKV2_AWS_62: development bucket, not production
#   bucket        = "terraform-state-bucket-2727"
#   force_destroy = true
#   tags = {
#     Name = "terraform-state-bucket-2727"
#   }
# }

# resource "aws_s3_bucket_public_access_block" "tf_state_public_access_block" {
#   bucket                  = aws_s3_bucket.tf_state.id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_versioning" "tf_state_versioning" {
#   bucket = aws_s3_bucket.tf_state.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
#   bucket = aws_s3_bucket.tf_state.id

#   rule {
#     apply_server_side_encryption_by_default {
#       kms_master_key_id = aws_kms_key.s3_bucket_key.arn
#       sse_algorithm     = "aws:kms"
#     }
#   }
# }

# resource "aws_s3_bucket_lifecycle_configuration" "tf_state_lifecycle" {
#   bucket = aws_s3_bucket.tf_state.id

#   rule {
#     id     = "expire-old-versions"
#     status = "Enabled"

#     filter {
#       prefix = "" # Replicate all objects
#     }

#     noncurrent_version_transition {
#       noncurrent_days = 30
#       storage_class   = "STANDARD_IA"
#     }

#     noncurrent_version_expiration {
#       noncurrent_days = 90
#     }
#   }

#   rule {
#     id     = "delete-old-objects"
#     status = "Enabled"

#     filter {
#       prefix = "" # Replicate all objects
#     }

#     expiration {
#       days = 365
#     }

#     abort_incomplete_multipart_upload {
#       days_after_initiation = 7
#     }
#   }
# }

# resource "aws_s3_bucket_logging" "tf_state_logging" {
#   bucket = aws_s3_bucket.tf_state.id

#   target_bucket = aws_s3_bucket.tf_state.id
#   target_prefix = "logs/"
# }
