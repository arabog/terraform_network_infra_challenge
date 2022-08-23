# VPC
resource "aws_vpc" "network_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "first_iac"
  }
}

# INTERNET GW
resource "aws_internet_gateway" "network_vpc_gw" {
  vpc_id = aws_vpc.network_vpc.id

  tags = {
    Name = "internet_gateway"
  }
}


# Resource.AlreadyAssociated: resource igw-0f7cabeee6890cfc9 is already attached to network vpc-069e6d321236075bb
# resource "aws_internet_gateway_attachment" "igw_attachment" {
#   internet_gateway_id = aws_internet_gateway.network_vpc_gw.id
#   vpc_id              = aws_vpc.network_vpc.id
# }

# SUBNETS: PUBLIC AND PRIVATE
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.network_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "network_public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.network_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"

  tags = {
    Name = "network_private_subnet"
  }
}

# ELASTIC IP
resource "aws_eip" "network_eip" {
  vpc = true
}

# NAT GW
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.network_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "gw_NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.network_vpc_gw]
}

# ROUTE TABLE, ROUTE AND ROUTE TABLE ASSOCIATION FOR PUBLIC SUBNET
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.network_vpc.id

  tags = {
    Name = "public_routetable"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.network_vpc_gw.id
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# ROUTE TABLE, ROUTE AND ROUTE TABLE ASSOCIATION FOR PRIVATE SUBNET
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.network_vpc.id

  tags = {
    Name = "private_routetable"
  }
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat_gw.id
}

resource "aws_route_table_association" "private_rta" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}
