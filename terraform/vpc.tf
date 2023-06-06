#VPC
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "finalproject_vpc"
  }
}

#PUBLIC SUBNET

resource "aws_subnet" "public_subnet" {
  count = length(var.az)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_cidr[count.index]
  availability_zone = var.az[count.index]
  tags = {
    Name = "public_subnet-${count.index}"
    "kubernetes.io/cluster/finalproject" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }
}

#PRIVATE SUBNET

resource "aws_subnet" "private_subnet" {
  count = length(var.az)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_cidr[count.index]
  availability_zone = var.az[count.index] 
  tags = {
    Name = "private_subnet-${count.index}"
  }
}

resource "aws_subnet" "eks_private_subnet" {
  count = length(var.az)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.eks_private_cidr[count.index]
  availability_zone = var.az[count.index] 
  tags = {
    Name = "eks_private_subnet-${count.index}"
    "kubernetes.io/cluster/finalproject" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"

  }
}

#Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internet_gateway"
  }
}

#NAT-GW

resource "aws_eip" "nat_gw" {
  vpc      = true
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat_gw.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "Public NAT GW"
  }
}

#Route Tabels (Proper routes)

resource "aws_route_table" "public_routes" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public routes"
  }
}

resource "aws_route_table_association" "routes_to_public_subnet0" {
  subnet_id      = aws_subnet.public_subnet[0].id
  route_table_id = aws_route_table.public_routes.id
}

resource "aws_route_table_association" "routes_to_public_subnet1" {
  subnet_id      = aws_subnet.public_subnet[1].id
  route_table_id = aws_route_table.public_routes.id
}

resource "aws_route_table" "private_routes" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }

  tags = {
    Name = "private routes"
  }
}

resource "aws_route_table_association" "routes_to_private_subnet0" {
  subnet_id      = aws_subnet.private_subnet[0].id
  route_table_id = aws_route_table.private_routes.id
}

resource "aws_route_table_association" "routes_to_private_subnet1" {
  subnet_id      = aws_subnet.private_subnet[1].id
  route_table_id = aws_route_table.private_routes.id
}

resource "aws_route_table_association" "routes_to_eks_private_subnet0" {
  subnet_id      = aws_subnet.eks_private_subnet[1].id
  route_table_id = aws_route_table.private_routes.id
}

resource "aws_route_table_association" "routes_to_eks_private_subnet1" {
  subnet_id      = aws_subnet.eks_private_subnet[1].id
  route_table_id = aws_route_table.private_routes.id
}