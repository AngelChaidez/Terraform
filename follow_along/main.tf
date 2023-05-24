terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
# create an ec2 t2.micro instance in region us-east-1
resource "aws_instance" "MyWebsite" {
  ami           = "ami-03c7d01cf4dedc891"
  instance_type = "t2.micro"

  tags = {
    Name = "HelloWorld"
  }
}