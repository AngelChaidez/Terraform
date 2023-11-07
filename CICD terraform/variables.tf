variable "instance_ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-03c7d01cf4dedc891"
}
 variable "ami_type" {
  description = "AMI type for the EC2 instance"
  type = string
  default = "t2.micro"
   
 }

# Define variables
variable "name" {
  description = "Name of the VPC"
  type        = string
  default     = "my-vpc"
}

variable "cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.10.3.0/24", "10.10.4.0/24"]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}
