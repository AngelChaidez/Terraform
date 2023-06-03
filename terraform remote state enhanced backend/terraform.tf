terraform {
  # I will uncomment if I desired to use Terraform cloud as my backend, this is already configured
  /*
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "cloudgeeks"
    workspaces {
      name = "my-aws-app"
    }
  } */
  /* Uncomment to add the backend to an S3 bucket
    backend "s3" {
    bucket = "my-terraform-state-bucket-achaidez"
    key    = "prod/aws_infra"
    region = "us-east-1"

    # Adding a dynamodb table
    dynamodb_table = "terraform-lock"
    encrypt        = true

  }*/
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "2.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}