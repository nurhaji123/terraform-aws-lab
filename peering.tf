# Second VPC, peered with the main VPC.
resource "aws_vpc" "peer" {
  cidr_block           = var.peer_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "tf-peer-vpc"
  }
}

resource "aws_subnet" "peer" {
  vpc_id                  = aws_vpc.peer.id
  cidr_block              = var.peer_subnet_cidr
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "tf-peer-subnet-1"
  }
}

resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = aws_vpc.main.id
  peer_vpc_id = aws_vpc.peer.id
  auto_accept = false

  tags = {
    Name = "tf-vpc-peering"
  }
}

# Both VPCs are in the same account and region, so the accepter is
# managed here rather than under a second provider alias.
resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true
}

resource "aws_route" "main_to_peer" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = aws_vpc.peer.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id

  depends_on = [aws_vpc_peering_connection_accepter.peer]
}

resource "aws_route_table" "peer" {
  vpc_id = aws_vpc.peer.id

  tags = {
    Name = "tf-peer-rt"
  }
}

resource "aws_route_table_association" "peer" {
  subnet_id      = aws_subnet.peer.id
  route_table_id = aws_route_table.peer.id
}

resource "aws_route" "peer_to_main" {
  route_table_id            = aws_route_table.peer.id
  destination_cidr_block    = aws_vpc.main.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id

  depends_on = [aws_vpc_peering_connection_accepter.peer]
}
