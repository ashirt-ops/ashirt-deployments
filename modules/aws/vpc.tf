resource "aws_vpc" "ashirt" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = local.name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ashirt.id

  tags = {
    Name = local.name
  }
}

# Public subnets host the internet-facing frontend load balancer and the NAT
# gateway. Private subnets host the ECS tasks, the internal load balancer, and
# the Aurora cluster.
resource "aws_subnet" "public" {
  count                   = var.az_count
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.ashirt.id
  cidr_block              = cidrsubnet(aws_vpc.ashirt.cidr_block, 4, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name}-public-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = var.az_count
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.ashirt.id
  cidr_block        = cidrsubnet(aws_vpc.ashirt.cidr_block, 4, var.az_count + count.index)

  tags = {
    Name = "${local.name}-private-${count.index}"
  }
}

# A single NAT gateway keeps the reference deployment affordable. Private
# subnets egress through it so ECS tasks can pull images and reach AWS APIs.
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.name}-nat"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = local.name
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ashirt.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.name}-public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ashirt.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${local.name}-private"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
