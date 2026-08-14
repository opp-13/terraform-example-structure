# CodePipeline manages its own object key layout inside this bucket (not user-controlled),
# so it gets a dedicated bucket rather than a prefix inside the tfstate bucket — this keeps
# IAM scoping for the state bucket and the pipeline artifact bucket cleanly separate.
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "${var.state_bucket_name}-pipeline-artifacts"

  tags = {
    Name = "${var.state_bucket_name}-pipeline-artifacts"
  }
}

resource "aws_s3_bucket_versioning" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
