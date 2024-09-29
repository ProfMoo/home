# Resources related to the S3 bucket to store music backups

resource "aws_s3_bucket" "music" {
  bucket = "sobrien-music"
}

resource "aws_s3_bucket_acl" "music" {
  bucket = aws_s3_bucket.music.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "music" {
  bucket = aws_s3_bucket.music.id

  rule {
    bucket_key_enabled = false

    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "glacier" {
  bucket = aws_s3_bucket.music.id

  rule {
    status = "Enabled"
    id     = "glacier"

    transition {
      days          = 1
      storage_class = "DEEP_ARCHIVE"
    }
  }
}
