terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "sobrien-home"
    key    = "home"
    region = "us-east-1"
    # To authenticate to access the state (not the actual plan)
    shared_credentials_file = "./aws-credentials"
  }
}

provider "aws" {
  region = "us-east-2"
  # To authenticate to access during the plan/apply phase
  shared_credentials_file = "./aws-credentials"
}

resource "aws_s3_bucket" "music" {
  bucket = "sobrien-music"
  acl    = "private"

  lifecycle_rule {
    id      = "glacier"
    enabled = true

    transition {
      days          = 1
      storage_class = "GLACIER"
    }
  }
}

resource "aws_iam_user" "nas" {
  name = "nas"

  tags = {
    description = "Used by Synology NAS to connect to the S3 replication backup"
  }
}

resource "aws_iam_access_key" "nas" {
  user = aws_iam_user.nas.name
}

resource "aws_iam_policy" "nas" {
  name        = "s3-bucket-access"
  path        = "/"
  description = "Allow the NAS full access to the music backup S3 bucket"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "s3:*"
        ],
        "Effect" : "Allow",
        "Resource" : [
          "${aws_s3_bucket.music.arn}",
          "${aws_s3_bucket.music.arn}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "nas" {
  name       = "attach-nas-to-s3-bucket"
  users      = [aws_iam_user.nas.name]
  policy_arn = aws_iam_policy.nas.arn
}

output "access_key_id" {
  value = aws_iam_access_key.nas.id
}

output "secret_access_key" {
  value     = aws_iam_access_key.nas.secret
  sensitive = true
}
