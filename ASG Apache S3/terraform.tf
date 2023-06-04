terraform {
  # Uncomment to add the backend to an S3 bucket
  backend "s3" {
    bucket = "my-terraform-state-bucket-achaidez"
    key    = "prod/aws_infra"
    region = "us-east-1"

    /*
    # Adding a dynamodb table
    dynamodb_table = "terraform-lock"
    encrypt        = true
    */
  }
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.1.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
  }
}