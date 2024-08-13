resource "aws_s3_bucket" "state_s3_bucket" {
  bucket = var.s3_bucket_name
  object_lock_enabled = true
  #force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "State Management"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "state_s3_bucket" {
  bucket = aws_s3_bucket.state_s3_bucket.id
  versioning_configuration {
    status = var.s3_bucket_versioning
  }
}

resource "aws_dynamodb_table" "terraform-lock" {
  name = var.dynamodb_table_name
  read_capacity = 5
  write_capacity = 5
  hash_key = var.dynamodb_hash
  
  attribute {
    name = var.dynamodb_hash
    type = "S"
  }
}
