provider "aws" {
  region = "us-east-1"
}

# Get your public IP
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

# Create Key Pair from local public key
resource "aws_key_pair" "deployer" {
  key_name   = "my-key"
  public_key = file("/Users/atul/.ssh/my-key.pub")  # ✅ Absolute path
}

# VPC A
resource "aws_vpc" "vpc_a" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC-A"
  }
}

# VPC B
resource "aws_vpc" "vpc_b" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "VPC-B"
  }
}

# Internet Gateways
resource "aws_internet_gateway" "igw_a" {
  vpc_id = aws_vpc.vpc_a.id
}

resource "aws_internet_gateway" "igw_b" {
  vpc_id = aws_vpc.vpc_b.id
}

# Subnets
resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.vpc_a.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.vpc_b.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-east-1a"
}

# Route Tables
resource "aws_route_table" "rt_a" {
  vpc_id = aws_vpc.vpc_a.id
}

resource "aws_route_table" "rt_b" {
  vpc_id = aws_vpc.vpc_b.id
}

# Route Table Associations
resource "aws_route_table_association" "rta_a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.rt_a.id
}

resource "aws_route_table_association" "rta_b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.rt_b.id
}

# VPC Peering
resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = aws_vpc.vpc_a.id
  peer_vpc_id   = aws_vpc.vpc_b.id
  auto_accept   = true
  tags = {
    Name = "A-to-B"
  }
}

# Routes for VPC Peering
resource "aws_route" "route_to_b" {
  route_table_id         = aws_route_table.rt_a.id
  destination_cidr_block = aws_vpc.vpc_b.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route" "route_to_a" {
  route_table_id         = aws_route_table.rt_b.id
  destination_cidr_block = aws_vpc.vpc_a.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

# Default Routes
resource "aws_route" "default_igw_route_a" {
  route_table_id         = aws_route_table.rt_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_a.id
}

resource "aws_route" "default_igw_route_b" {
  route_table_id         = aws_route_table.rt_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_b.id
}

# Security Group A
resource "aws_security_group" "sg_common" {
  name        = "vpc-a-sg"
  description = "Allow SSH & ICMP"
  vpc_id      = aws_vpc.vpc_a.id

  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [chomp(data.http.my_ip.response_body) + "/32"]
  }

  ingress {
    description = "ICMP from internal VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-VPC-A"
  }
}

# Security Group B
resource "aws_security_group" "sg_common_b" {
  name        = "vpc-b-sg"
  description = "Allow SSH & ICMP"
  vpc_id      = aws_vpc.vpc_b.id

  ingress {
    description = "SSH from VPC A"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "ICMP from internal VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-VPC-B"
  }
}

# EC2 Instances
resource "aws_instance" "ec2_a" {
  ami                         = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_a.id
  vpc_security_group_ids      = [aws_security_group.sg_common.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  tags = {
    Name = "EC2-A"
  }
}

resource "aws_instance" "ec2_b" {
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_b.id
  vpc_security_group_ids      = [aws_security_group.sg_common_b.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  tags = {
    Name = "EC2-B"
  }
}
