# create an AWS s3 bucket with best security practices that allows versioning and 
# allows customizing lifecycle policies

# AWS S3 bucket
variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket to create"
}

variable "aws_region" {
  type        = string
  description = "AWS region to create the S3 bucket in"
}

variable "enable_versioning" {
  type        = bool
  description = "Whether to enable versioning on the S3 bucket"
  default     = true
}

variable "enable_loggin" {
    type        = bool
    description = "Whether to enable logging on the S3 bucket"
    default     = true
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = var.s3_bucket_name
  region = var.aws_region

  force_destroy = true

  lifecycle_rule {
    id      = "delete_after_30_days"
    enabled = true

    expiration {
      days = 30
    }
  }

  versioning {
    enabled = var.enable_versioning
  }

  logging {
    target_bucket = var.enable_loggin
    target_prefix = "${var.s3_bucket_name}"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

}

output "bucket_id" {
    value = aws_s3_bucket.my_bucket.id
  
}