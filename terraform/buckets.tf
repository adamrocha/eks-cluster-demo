resource "aws_s3_bucket" "project_bucket" {
  bucket        = "project-bucket-2727"
  force_destroy = true
  tags = {
    Name = "project-bucket-2727"
  }
}

resource "aws_s3_bucket" "project_bucket_replica" {
  depends_on    = [aws_s3_bucket.project_bucket]
  bucket        = "project-bucket-2727-replica"
  force_destroy = true
  tags = {
    Name = "project-bucket-2727-replica"
  }
}

resource "aws_s3_bucket_public_access_block" "project_bucket_public_access_block" {
  depends_on              = [aws_s3_bucket.project_bucket]
  bucket                  = aws_s3_bucket.project_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "project_bucket_replica_public_access_block" {
  depends_on              = [aws_s3_bucket.project_bucket_replica]
  bucket                  = aws_s3_bucket.project_bucket_replica.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "project_bucket_versioning" {
  depends_on = [
    aws_s3_bucket.project_bucket,
    aws_s3_bucket.project_bucket_replica
  ]
  bucket = aws_s3_bucket.project_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "project_bucket_replica_versioning" {
  depends_on = [
    aws_s3_bucket.project_bucket,
    aws_s3_bucket.project_bucket_replica
  ]
  bucket = aws_s3_bucket.project_bucket_replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "project_bucket_encryption" {
  bucket = aws_s3_bucket.project_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_bucket_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "project_bucket_replica_encryption" {
  bucket = aws_s3_bucket.project_bucket_replica.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_bucket_key.arn # Or a different KMS key
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "project_bucket_lifecycle" {
  bucket = aws_s3_bucket.project_bucket.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {
      prefix = "" # Replicate all objects
    }

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

    filter {
      prefix = "" # Replicate all objects
    }

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "project_bucket_replica_lifecycle" {
  bucket = aws_s3_bucket.project_bucket_replica.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {
      prefix = "" # Replicate all objects
    }

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

    filter {
      prefix = "" # Replicate all objects
    }

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_logging" "project_bucket_logging" {
  bucket = aws_s3_bucket.project_bucket.id

  target_bucket = aws_s3_bucket.project_bucket.id
  target_prefix = "logs/"
}

resource "aws_s3_bucket_logging" "project_bucket_replica_logging" {
  bucket = aws_s3_bucket.project_bucket_replica.id

  target_bucket = aws_s3_bucket.project_bucket_replica.id
  target_prefix = "replica-logs/"
}

resource "aws_s3_bucket_notification" "project_bucket_notification" {
  bucket = aws_s3_bucket.project_bucket.id

  # Example: Add a lambda function notification (replace with your actual lambda ARN)
  # lambda_function {
  #   lambda_function_arn = aws_lambda_function.example.arn
  #   events              = ["s3:ObjectCreated:*"]
  # }
}

resource "aws_s3_bucket_notification" "project_bucket_replica_notification" {
  bucket = aws_s3_bucket.project_bucket_replica.id

  # Example: Add a lambda function notification (replace with your actual lambda ARN)
  # lambda_function {
  #   lambda_function_arn = aws_lambda_function.example.arn
  #   events              = ["s3:ObjectCreated:*"]
  # }
}

resource "aws_s3_bucket_replication_configuration" "project_bucket_replication" {
  depends_on = [
    aws_s3_bucket_versioning.project_bucket_versioning,
    aws_s3_bucket_versioning.project_bucket_replica_versioning
  ]
  bucket = aws_s3_bucket.project_bucket.id
  role   = aws_iam_role.s3_replication.arn

  rule {
    id = "replication-rule"

    filter {
      prefix = "" # Replicate all objects
    }

    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.project_bucket_replica.arn
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