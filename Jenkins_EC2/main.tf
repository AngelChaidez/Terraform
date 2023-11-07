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


# Configure the Security Group to allow traffic from on port 22 (SSH) and port 8080.
resource "aws_security_group" "jenkins_security_group" {
  name        = "jenkins-ec2-${terraform.workspace}"
  description = "Security group for Jenkins instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Generate a key for the security group and the instance
resource "tls_private_key" "generated" {
  algorithm = "RSA"
}
resource "local_file" "private_key_pem" {
  content  = tls_private_key.generated.private_key_pem
  filename = "JenkinsCICD.pem"
}
resource "aws_key_pair" "generated" {
  key_name   = "JenkinsCICD"
  public_key = tls_private_key.generated.public_key_openssh
  lifecycle {
    ignore_changes = [key_name]
  }
}

# Configure the AWS EC2 instance, to use created security group and our keypair we will create and use
resource "aws_instance" "Jenkins_EC2_Instance" {
  ami                         = "ami-03c7d01cf4dedc891"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.jenkins_security_group.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated.key_name
  connection {
    user        = "ec2-user"
    private_key = tls_private_key.generated.private_key_pem
    host        = self.public_ip
  }
  provisioner "local-exec" {
    command = "chmod 600 ${local_file.private_key_pem.filename}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key",
      "sudo yum upgrade -y",
      "sudo amazon-linux-extras install java-openjdk11 -y",
      "sudo yum install jenkins -y",
      "sudo systemctl enable jenkins",
      "sudo systemctl start jenkins",
      "sudo systemctl status jenkins"
    ]
  }

  tags = {
    Name = "Jennkins_CI/CD"
  }

}
# Add resource to create an S3 bucket with random suffix for the project name
resource "random_id" "randomness" {
  byte_length = 2
}

# Create a S3 bucket with random suffix for the project name. This project will be private and not accesible
# to the public
resource "aws_s3_bucket" "my-new-S3-bucket" {
  bucket = "my-jenkins-cicd-s3-bucket-achaidez-${random_id.randomness.hex}"

  tags = {
    Name    = "My S3 Bucket"
    Purpose = "Intro to Resource Blocks Lab"
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
