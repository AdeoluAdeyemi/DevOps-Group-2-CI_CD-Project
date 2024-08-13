# Configuration file
terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.62.0"
        }
    }

    required_version = ">= 1.8.5"

  # backend "s3" {
  #   bucket = "terraform-state-backend"
  #   key = "terraform.tfstate"
  #   region = "eu-west-2"
  #   dynamodb_table = "terraform_state"
  # }
}

# terraform {

# }