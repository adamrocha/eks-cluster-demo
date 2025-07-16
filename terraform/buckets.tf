resource "aws_s3_bucket" "tf_state" {
  bucket        = "terraform-state-bucket-1337-8647"
  force_destroy = true
}

resource "aws_s3_bucket" "tf_state_replica" {
  bucket        = "terraform-state-bucket-1337-8647-replica"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "tf_state_replica_public_access_block" {
  bucket                  = aws_s3_bucket.tf_state_replica.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "tf_state_replica_versioning" {
  bucket = aws_s3_bucket.tf_state_replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "tf_state_replica_lifecycle" {
  bucket = aws_s3_bucket.tf_state_replica.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "delete-old-objects"
    status = "Enabled"

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "tf_state_replica_logging" {
  bucket = aws_s3_bucket.tf_state_replica.id

  target_bucket = aws_s3_bucket.tf_state.id
  target_prefix = "replica-logs/"
}

resource "aws_s3_bucket_notification" "tf_state_replica_notification" {
  bucket = aws_s3_bucket.tf_state_replica.id

  # Example: Add a lambda function notification (replace with your actual lambda ARN)
  # lambda_function {
  #   lambda_function_arn = aws_lambda_function.example.arn
  #   events              = ["s3:ObjectCreated:*"]
  # }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_replica_encryption" {
  bucket = aws_s3_bucket.tf_state_replica.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_bucket_key.arn # Or a different KMS key
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_encryption" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state_public_access_block" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "tf_state_lifecycle" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "delete-old-objects"
    status = "Enabled"

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_replication_configuration" "tf_state_replication" {
  bucket = aws_s3_bucket.tf_state.id
  role   = aws_iam_role.s3_replication.arn

  depends_on = [
    aws_s3_bucket.tf_state_replica,
  ]

  rule {
    id = "tf-state-cross-region-replication"

    filter {
      prefix = "" # Replicate all objects
    }

    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.tf_state_replica.arn
      storage_class = "STANDARD"

      # Ensure this block is consistent with your KMS setup if applicable
      # (Only if the replica bucket is also KMS encrypted)
      # You might also need 'access_control_translation' for cross-account replication
      # or if owner values differ.

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    delete_marker_replication {
      status = "Disabled" # Or "Enabled", depending on your requirement
      # Add server-side encryption for the replica bucket if desired,
    }
  }
}