output "has_s3_bucket_name" {
  description = "Returns the name of an S3 bucket if it exist"
  value = data.aws_s3_bucket.check_s3_bucket_exist.id
}

output "has_dynamodb_table_name" {
  description = "Returns the name of an DynamoDB table if it exist"
  value = data.aws_dynamodb_table.check_dynamodb_table_exist.id
}