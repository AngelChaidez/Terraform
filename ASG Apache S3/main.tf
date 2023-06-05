provider "aws" {
  region = "us-east-1"

}
data "aws_vpc" "default" {
  default = true
}

#Retrieve the list of AZs in the current AWS region
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

/*
Create a security group that allows internet access and allows for incoming traffic on ports
22 for SSH access, ports 80 for internet access via our web browser via HTTP and ports 443 for HTTPS
*/
resource "aws_security_group" "autoscaling" {
  name        = "autoscaling_group_${terraform.workspace}"
  description = "Allow incoming traffic access to the security group"
  # from port 22 
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # We want internet to access it
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.autoscaling_lb.id]
  }
  # from port 80
  ingress {
    description     = "Allow incoming traffic on port 80"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.autoscaling_lb.id]
  }
  # from port 443
  ingress {
    description     = "Allow incoming traffic on port 443"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.autoscaling_lb.id]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.autoscaling_lb.id]
  }
  vpc_id = data.aws_vpc.default.id
}
/*
Security group for our LoadBalancer, this will ensure that our EC2 instances receive traffic
only from our LoadBalancer
*/
resource "aws_security_group" "autoscaling_lb" {
  name = "learn-asg-ec2-lb"
  ingress {
    description = "Allow incoming traffic on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
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
  vpc_id = data.aws_vpc.default.id
}

# Generate a key for the security group and the instance
resource "tls_private_key" "generated" {
  algorithm = "RSA"
}
resource "local_file" "private_key_pem" {
  content  = tls_private_key.generated.private_key_pem
  filename = "ASG-Apache-S3.pem"
}
resource "aws_key_pair" "generated" {
  key_name   = "ASG-Apache-S3"
  public_key = tls_private_key.generated.public_key_openssh
  lifecycle {
    ignore_changes = [key_name]
  }
}
/*
Create a launch configuration for our EC2 instances and our autoscaling group
*/
resource "aws_launch_configuration" "asg_launch_config" {
  name                        = "asg-launch-config"
  image_id                    = var.instance_ami
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.autoscaling.id]
  key_name                    = aws_key_pair.generated.key_name
  user_data                   = file("user-data.sh")
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
  connection {
    user        = "ec2-user"
    private_key = tls_private_key.generated.private_key_pem
    host        = self.associate_public_ip_address
  }

  provisioner "local-exec" {
    command = "chmod 600 ${local_file.private_key_pem.filename}"
  }

}
/*
Target groups will route our traffic to our EC2 instances based on the port 80 
and protocol HTTP 
*/
resource "aws_lb_target_group" "asg_target_group" {
  name     = "target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

}
/*
Autoscaling attachemnt will attach our LB to our autoscaling group
*/
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group.id
  lb_target_group_arn    = aws_lb_target_group.asg_target_group.arn

}
resource "aws_placement_group" "autoscaling_group" {
  name     = "auto_scaling_group"
  strategy = "cluster"
}
/*
Autoscaling group to run on two public subnets using our launch configuration, we will
keep our running instances at two when traffic is slow and scale up to 5 when traffic is high
*/

resource "aws_autoscaling_group" "autoscaling_group" {
  name                 = "project_auto_scaling_group"
  max_size             = 5
  min_size             = 2
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.asg_launch_config.name
  vpc_zone_identifier  = ["subnet-0665df2b34c0238b4", "subnet-0dbda85a0052e8218"]

  tag {
    key                 = "Name"
    value               = "launch-instance"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }

}

# Load Balancer 
resource "aws_lb" "asg_ec2_instance" {
  name               = "asg-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.autoscaling.id, aws_security_group.autoscaling_lb.id]
  subnets            = ["subnet-0665df2b34c0238b4", "subnet-0dbda85a0052e8218"]
}

# Load Balancer listener
resource "aws_lb_listener" "asg_ec2_instance" {
  load_balancer_arn = aws_lb.asg_ec2_instance.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg_target_group.arn
  }

}



