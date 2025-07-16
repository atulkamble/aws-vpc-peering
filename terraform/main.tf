provider "aws" {
  region = var.region
}

# VPC A
resource "aws_vpc" "vpc_a" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "VPC-A" }
}

resource "aws_subnet" "subnet_a" {
  vpc_id     = aws_vpc.vpc_a.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.az
  tags = { Name = "Subnet-A" }
}

# VPC B
resource "aws_vpc" "vpc_b" {
  cidr_block = "10.1.0.0/16"
  tags = { Name = "VPC-B" }
}

resource "aws_subnet" "subnet_b" {
  vpc_id     = aws_vpc.vpc_b.id
  cidr_block = "10.1.1.0/24"
  availability_zone = var.az
  tags = { Name = "Subnet-B" }
}

# VPC Peering
resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = aws_vpc.vpc_a.id
  peer_vpc_id   = aws_vpc.vpc_b.id
  auto_accept   = true

  tags = {
    Name = "VPC-A-to-VPC-B"
  }
}

# Route tables for VPC A
resource "aws_route_table" "rt_a" {
  vpc_id = aws_vpc.vpc_a.id
}

resource "aws_route" "route_to_b" {
  route_table_id            = aws_route_table.rt_a.id
  destination_cidr_block    = aws_vpc.vpc_b.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route_table_association" "rta_a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.rt_a.id
}

# Route tables for VPC B
resource "aws_route_table" "rt_b" {
  vpc_id = aws_vpc.vpc_b.id
}

resource "aws_route" "route_to_a" {
  route_table_id            = aws_route_table.rt_b.id
  destination_cidr_block    = aws_vpc.vpc_a.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

resource "aws_route_table_association" "rta_b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.rt_b.id
}

# Security Groups
resource "aws_security_group" "sg_common" {
  name   = "allow-ssh-ping"
  vpc_id = aws_vpc.vpc_a.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "10.1.0.0/8"]
  }

  ingress {
    description = "Ping"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/8", "10.1.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Allow-Internal-Traffic" }
}

resource "aws_security_group" "sg_common_b" {
  name   = "allow-ssh-ping-b"
  vpc_id = aws_vpc.vpc_b.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "10.1.0.0/8"]
  }

  ingress {
    description = "Ping"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/8", "10.1.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Allow-Internal-Traffic-B" }
}

# EC2 in VPC A
resource "aws_instance" "ec2_a" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_a.id
  vpc_security_group_ids      = [aws_security_group.sg_common.id]
  associate_public_ip_address = true
  tags = { Name = "EC2-A" }
}

# EC2 in VPC B
resource "aws_instance" "ec2_b" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_b.id
  vpc_security_group_ids      = [aws_security_group.sg_common_b.id]
  associate_public_ip_address = true
  tags = { Name = "EC2-B" }
}
