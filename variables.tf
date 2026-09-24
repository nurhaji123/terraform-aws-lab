variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones for the public subnets"
  type        = list(string)
}

variable "my_ip" {
  description = "Public IP address allowed to connect using SSH"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private RDS subnets"
  type        = list(string)

  default = [
    "10.0.101.0/24",
    "10.0.102.0/24"
  ]
}

variable "db_password" {
  description = "Password for the RDS database administrator"
  type        = string
  sensitive   = true
}

variable "ami_id" {
  description = "Pinned AMI ID for the web server (Amazon Linux 2, us-east-1)"
  type        = string
  default     = "ami-021b301745ba3b19b"
}

variable "instance_type" {
  description = "EC2 instance type for the web server"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key uploaded as an EC2 key pair"
  type        = string
  default     = "~/.ssh/tf-web-server.pub"
}

variable "peer_vpc_cidr" {
  description = "CIDR block for the peer VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "peer_subnet_cidr" {
  description = "CIDR block for the peer VPC subnet"
  type        = string
  default     = "10.1.1.0/24"
}
