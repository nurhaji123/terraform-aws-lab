# Instance-level, stateful firewall.
resource "aws_security_group" "web" {
  name        = "tf-web-sg"
  description = "Allow SSH from my IP and HTTP from anywhere"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from my public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-web-sg"
  }
}

# Subnet-level, stateless firewall. Because NACLs are stateless, return
# traffic needs explicit rules in the opposite direction — hence the
# ephemeral-port entries below.
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tf-public-nacl"
  }
}

resource "aws_network_acl_rule" "inbound_ssh" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = var.my_ip
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "inbound_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

# Return traffic for outbound TCP connections (yum, HTTPS).
resource "aws_network_acl_rule" "inbound_ephemeral_tcp" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Return traffic for DNS, which is UDP.
resource "aws_network_acl_rule" "inbound_ephemeral_udp" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 130
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "outbound_tcp" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "outbound_udp" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 65535
}

# Apply the NACL to both public subnets.
resource "aws_network_acl_association" "public" {
  count = length(var.public_subnet_cidrs)

  network_acl_id = aws_network_acl.public.id
  subnet_id      = aws_subnet.public[count.index].id
}
