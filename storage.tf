# Generate a reusable random suffix for globally unique S3 bucket names.
resource "random_pet" "bucket_suffix" {
  length = 2
}

# Create two S3 buckets.
resource "aws_s3_bucket" "app_data" {
  count = 2

  bucket = "tf-app-data-${random_pet.bucket_suffix.id}-${count.index}"

  tags = {
    Name = "tf-app-data-bucket-${count.index}"
  }
}

# Enable versioning on both S3 buckets.
resource "aws_s3_bucket_versioning" "app_data" {
  count = 2

  bucket = aws_s3_bucket.app_data[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Create an additional EBS volume in the same Availability Zone
# as the existing EC2 instance.
resource "aws_ebs_volume" "extra_data" {
  availability_zone = aws_instance.web.availability_zone
  size              = 1
  type              = "gp2"

  tags = {
    Name = "tf-extra-data-volume"
  }
}

# Attach the EBS volume to the existing EC2 instance.
resource "aws_volume_attachment" "extra_data" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.extra_data.id
  instance_id = aws_instance.web.id
}

# Create the managed MySQL RDS database.
resource "aws_db_instance" "app_database" {
  identifier             = "tf-app-database"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  db_name                = "myappdb"
  username               = "adminuser"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.app_database.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = false
  skip_final_snapshot    = true

  tags = {
    Name = "tf-app-database"
  }
}
