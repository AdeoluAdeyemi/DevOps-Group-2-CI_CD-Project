variable "s3_bucket_name" {
  description = "Name of S3 bucket"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of DynamoDB table"
  type        = string
}

variable "dynamodb_hash" {
  description = "DynamoDB table hash key"
  type        = string
}

variable "s3_bucket_versioning" {
  description = "Status of s3 bucket versioning"
  type        = string
}