provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "demo-server" {
  ami                    = "ami-075686beab831bb7f"
  instance_type          = "t2.micro"
  key_name               = "automationsaan"
  vpc_security_group_ids = [aws_security_group.demo-sg.id] // Use the security group ID
  subnet_id              = aws_subnet.automationsaan-public-subnet-01.id
  for_each               = toset(["jenkins-master", "build-slave", "ansible"])
  tags = {
    Name = "${each.key}"
  }
}

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

resource "aws_vpc" "automationsaan-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "automationsaan-vpc"
  }

}

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

resource "aws_internet_gateway" "automationsaan-igw" {
  vpc_id = aws_vpc.automationsaan-vpc.id
  tags = {
    Name = "automationsaan-igw"
  }
}

resource "aws_route_table" "automationsaan-public-rt" {
  vpc_id = aws_vpc.automationsaan-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.automationsaan-igw.id
  }
}

resource "aws_route_table_association" "automationsaan-rta-public-subnet-01" {
  subnet_id      = aws_subnet.automationsaan-public-subnet-01.id
  route_table_id = aws_route_table.automationsaan-public-rt.id
}

resource "aws_route_table_association" "automationsaan-rta-public-subnet-02" {
  subnet_id      = aws_subnet.automationsaan-public-subnet-02.id
  route_table_id = aws_route_table.automationsaan-public-rt.id
}