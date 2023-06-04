variable "instance_ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-03c7d01cf4dedc891"
}


/*
resource "aws_s3_bucket" "my-new-S3-bucket" {
  bucket = "my-terraform-state-bucket-achaidez"

  tags = {
    Name    = "My S3 Bucket"
    Purpose = "Bucket to hold our backend"
  }
}
resource "aws_s3_bucket_acl" "my_new_bucket_acl" {
  bucket     = aws_s3_bucket.my-new-S3-bucket.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.s3_bucket_acl_ownership]
}
resource "aws_s3_bucket_ownership_controls" "s3_bucket_acl_ownership" {
  bucket = aws_s3_bucket.my-new-S3-bucket.id
  rule {
    object_ownership = "ObjectWriter"
  }
}
*/