# Trust policy:
# Allows the EC2 service to assume this IAM role.
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM role assumed by the EC2 instance.
resource "aws_iam_role" "ec2_s3_read" {
  name               = "tf-ec2-s3-read-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "tf-ec2-s3-read-role"
  }
}

# Read-only S3 permissions.
data "aws_iam_policy_document" "s3_readonly" {
  # Required for `aws s3 ls` with no bucket specified.
  statement {
    sid    = "ListAllBuckets"
    effect = "Allow"

    actions = [
      "s3:ListAllMyBuckets"
    ]

    resources = ["*"]
  }

  # Allows listing objects inside any bucket.
  statement {
    sid    = "ListBucketContents"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::*"
    ]
  }

  # Allows downloading and reading objects.
  statement {
    sid    = "ReadObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::*/*"
    ]
  }
}

# Reusable IAM policy containing the S3 permissions.
resource "aws_iam_policy" "s3_readonly" {
  name        = "tf-s3-readonly-policy"
  description = "Allow EC2 instances to list S3 buckets and read S3 objects"
  policy      = data.aws_iam_policy_document.s3_readonly.json

  tags = {
    Name = "tf-s3-readonly-policy"
  }
}

# Attach the S3 policy to the EC2 role.
resource "aws_iam_role_policy_attachment" "ec2_s3_read" {
  role       = aws_iam_role.ec2_s3_read.name
  policy_arn = aws_iam_policy.s3_readonly.arn
}

# Instance profile used to attach the IAM role to EC2.
resource "aws_iam_instance_profile" "ec2_s3_read" {
  name = "tf-ec2-s3-read-profile"
  role = aws_iam_role.ec2_s3_read.name

  tags = {
    Name = "tf-ec2-s3-read-profile"
  }
}
