output "s3_bucket_names" {
  description = "Names of the application data S3 buckets"
  value       = aws_s3_bucket.app_data[*].bucket
}

output "ebs_volume_id" {
  description = "ID of the additional EBS data volume"
  value       = aws_ebs_volume.extra_data.id
}

output "rds_endpoint" {
  description = "Endpoint of the RDS MySQL database"
  value       = aws_db_instance.app_database.endpoint
}

output "rds_port" {
  description = "Port of the RDS MySQL database"
  value       = aws_db_instance.app_database.port
}
