# Upload the local public key to AWS.
resource "aws_key_pair" "web" {
  key_name   = "tf-web-server-key"
  public_key = file(pathexpand(var.ssh_public_key_path))

  tags = {
    Name = "tf-web-server-key"
  }
}

# Apache web server.
#
# The AMI is pinned via variable rather than resolved with most_recent,
# so an upstream Amazon Linux release cannot silently replace the
# instance during an unrelated plan.
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.web.key_name

  subnet_id = aws_subnet.public[1].id

  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_s3_read.name

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  user_data = <<-EOT
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello World from Terraform EC2 $(hostname -f)</h1>" > /var/www/html/index.html
  EOT

  tags = {
    Name = "tf-web-server"
  }
}
