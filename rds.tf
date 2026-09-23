# Private subnets for the RDS database.
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "tf-private-subnet-${count.index + 1}"
  }
}

# Private route tables intentionally have no route to the Internet Gateway.
resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tf-private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Tells RDS which private subnets it may use.
resource "aws_db_subnet_group" "app_database" {
  name       = "tf-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "tf-db-subnet-group"
  }
}

# Database security group. Ingress is restricted to the web server's
# security group rather than a CIDR, so the rule survives IP changes.
resource "aws_security_group" "db" {
  name        = "tf-db-sg"
  description = "Allow MySQL access from the web server security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from web server"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-db-sg"
  }
}
