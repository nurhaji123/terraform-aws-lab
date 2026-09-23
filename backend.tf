# Partial backend configuration.
# Bucket and key are supplied at init time via backend.hcl, which is
# gitignored because the bucket name embeds the AWS account ID.
#
#   terraform init -backend-config=backend.hcl
terraform {
  backend "s3" {
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
