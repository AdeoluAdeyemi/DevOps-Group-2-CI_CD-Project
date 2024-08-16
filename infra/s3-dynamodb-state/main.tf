resource "aws_s3_bucket" "state_s3_bucket" {
  bucket              = var.s3_bucket_name
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
  name           = var.dynamodb_table_name
  read_capacity  = 5
  write_capacity = 5
  hash_key       = var.dynamodb_hash

  attribute {
    name = var.dynamodb_hash
    type = "S"
  }
}

data "aws_iam_user" "user" {
  user_name = "adeolu"
}


resource "aws_iam_policy" "dynamodb_pol" {
  name        = "dynamodb_policy"
  path        = "/"
  description = "My DynamoDB policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "DyanmoDBAccess",
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:BatchGetItem",
            "dynamodb:BatchWriteItem",
            "dynamodb:ConditionCheckItem",
            "dynamodb:PutItem",
            "dynamodb:DescribeTable",
            "dynamodb:DeleteItem",
            "dynamodb:GetItem",
            "dynamodb:Scan",
            "dynamodb:Query",
            "dynamodb:UpdateItem"
          ],
          "Resource" : [
            aws_dynamodb_table.terraform-lock.arn
            #"arn:aws:dynamodb:eu-west-2:637423624556:table/terraform_state"
          ]
        }
      ]
    }
  )
}