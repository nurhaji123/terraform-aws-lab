output "vpc_id" {
  description = "ID of the main VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "web_sg_id" {
  description = "ID of the web server security group"
  value       = aws_security_group.web.id
}

output "public_nacl_id" {
  description = "ID of the custom public network ACL"
  value       = aws_network_acl.public.id
}

output "web_server_public_ip" {
  description = "Public IP address of the EC2 web server"
  value       = aws_instance.web.public_ip
}

output "web_server_public_dns" {
  description = "Public DNS name of the EC2 web server"
  value       = aws_instance.web.public_dns
}

output "web_server_instance_id" {
  description = "ID of the EC2 web server"
  value       = aws_instance.web.id
}

output "amazon_linux_2_ami_id" {
  description = "Pinned AMI ID used by the web server"
  value       = var.ami_id
}

output "vpc_peering_id" {
  description = "ID of the VPC peering connection"
  value       = aws_vpc_peering_connection.peer.id
}

output "peer_vpc_id" {
  description = "ID of the peer VPC"
  value       = aws_vpc.peer.id
}
