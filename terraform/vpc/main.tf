# Terraform configuration for AWS infrastructure
# This file provisions a VPC, subnets, security group, EC2 instances, and networking resources for a DevOps project.

provider "aws" {
  region = "us-west-2" # Set the AWS region
}

# Create multiple EC2 instances for Jenkins master, build slave, and Ansible
resource "aws_instance" "demo-server" {
  ami                    = "ami-075686beab831bb7f" # Amazon Machine Image ID
  instance_type          = "t2.small"  # Instance type (can be changed as needed)
  key_name               = "automationsaan" # SSH key name
  vpc_security_group_ids = [aws_security_group.demo-sg.id] # Attach security group
  subnet_id              = aws_subnet.automationsaan-public-subnet-01.id # Attach to public subnet
  for_each               = toset(["jenkins-master", "build-slave", "ansible"]) # Create one instance for each role
  tags = {
    Name = "${each.key}"
  }
}

# Security group allowing SSH and Jenkins access
resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "SSH Access"
  vpc_id      = aws_vpc.automationsaan-vpc.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssh-prot"
  }
}

# VPC for the project
resource "aws_vpc" "automationsaan-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "automationsaan-vpc"
  }
}

# Public subnets in two availability zones
resource "aws_subnet" "automationsaan-public-subnet-01" {
  vpc_id                  = aws_vpc.automationsaan-vpc.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-west-2a"
  tags = {
    Name = "automationsaan-public-subent-01"
  }
}

resource "aws_subnet" "automationsaan-public-subnet-02" {
  vpc_id                  = aws_vpc.automationsaan-vpc.id
  cidr_block              = "10.1.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-west-2b"
  tags = {
    Name = "automationsaan-public-subent-02"
  }
}

# Internet gateway for VPC
resource "aws_internet_gateway" "automationsaan-igw" {
  vpc_id = aws_vpc.automationsaan-vpc.id
  tags = {
    Name = "automationsaan-igw"
  }
}

# Route table for public subnets
resource "aws_route_table" "automationsaan-public-rt" {
  vpc_id = aws_vpc.automationsaan-vpc.id
  # Route all outbound traffic to the internet via the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.automationsaan-igw.id
  }
}

# Associate each public subnet with the public route table so they have internet access
resource "aws_route_table_association" "automationsaan-rta-public-subnet-01" {
  subnet_id      = aws_subnet.automationsaan-public-subnet-01.id
  route_table_id = aws_route_table.automationsaan-public-rt.id
}

resource "aws_route_table_association" "automationsaan-rta-public-subnet-02" {
  subnet_id      = aws_subnet.automationsaan-public-subnet-02.id
  route_table_id = aws_route_table.automationsaan-public-rt.id
}

# Create security groups for EKS and other resources using a module
module "sgs" {
  source = "../sg_eks"
  vpc_id = aws_vpc.automationsaan-vpc.id
}

# Create an EKS cluster using a module, passing VPC, subnet, and security group info
module "eks" {
  source    = "../eks"
  vpc_id    = aws_vpc.automationsaan-vpc.id
  subnet_ids = [aws_subnet.automationsaan-public-subnet-01.id, aws_subnet.automationsaan-public-subnet-02.id]
  sg_ids    = module.sgs.security_group_public
}