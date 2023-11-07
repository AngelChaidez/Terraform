provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  enable_vpn_gateway   = true
  enable_dns_support   = true
  enable_dns_hostnames = true
  single_nat_gateway   = false
  reuse_nat_ips        = true             # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids  = aws_eip.nat.*.id # <= IPs specified here as input to the module

  tags = {
    Name        = "CICD-terraform"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_eip" "nat" {
  count = 2
}



resource "aws_security_group" "cicd_security_group" {
  name        = "autoscaling_group_${terraform.workspace}"
  description = "Allow incoming traffic access to the security group"
  # from port 22 
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # from port 80
  ingress {
    description = "Allow incoming traffic on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # from port 443
  ingress {
    description = "Allow incoming traffic on port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
  vpc_id = module.vpc.vpc_id
}

# Create a security group for an RDS MySQL server
resource "aws_security_group" "rds_security_group" {
  name = "rds_security_group_${terraform.workspace}"
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.bastion_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "bastion_security_group" {
  name        = "bastion_security_group"
  description = "Allow SSH access to the bastion host"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id
}

# Create a EC2 instance in each public subnet
module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  for_each = {
    for index, subnet in module.vpc.public_subnets :
    index => subnet
  }
  name                        = "cicd-${each.key}"
  ami                         = var.instance_ami
  instance_type               = var.ami_type
  key_name                    = "EastCoastKP"
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.cicd_security_group.id, aws_security_group.bastion_security_group.id]
  subnet_id                   = module.vpc.public_subnets[each.key]
  user_data                   = file("user-data.sh")
  associate_public_ip_address = true


  tags = {
    Name        = "CICD-terraform-${each.key}"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "null_resource" "example" {
  for_each = {
    for index, name in module.ec2_instance :
    index => name
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("EastCoastKP.pem")
    host        = module.ec2_instance[each.key].public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo Connected to ${each.key}"
    ]
  }
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "my-db-subnet-group"
  subnet_ids = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]

  tags = {
    Name      = "DB Subnet Group"
    Terraform = "true"
  }
}

resource "aws_db_instance" "cicd-rds-instance" {
  allocated_storage      = 5
  db_name                = "mydb"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  username               = "user"
  password               = "my_password"
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.id
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
}
