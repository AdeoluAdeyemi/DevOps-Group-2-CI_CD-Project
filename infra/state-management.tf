data "aws_s3_bucket" "check_s3_bucket_exist" {
  bucket = "govuk-fe-demo-terraform-state-backend"
}

data "aws_dynamodb_table" "check_dynamodb_table_exist" {
  name = "terraform_state"
}

resource "aws_s3_bucket" "state_s3_bucket" {
  count = (data.aws_s3_bucket.check_s3_bucket_exist.id == "govuk-fe-demo-terraform-state-backend") ? 0 : 1
  bucket = "govuk-fe-demo-terraform-state-backend"
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
  count = (data.aws_s3_bucket.check_s3_bucket_exist.id == "govuk-fe-demo-terraform-state-backend") ? 0 : 1
  bucket = (data.aws_s3_bucket.check_s3_bucket_exist.id == "govuk-fe-demo-terraform-state-backend") ? null : data.aws_s3_bucket.check_s3_bucket_exist.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform-lock" {
  count = (data.aws_dynamodb_table.check_dynamodb_table_exist.id == "terraform_state") ? 0 : 1
  name = "terraform_state"
  read_capacity = 5
  write_capacity = 5
  hash_key = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
}
