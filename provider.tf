terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
provider "aws" {
  region     = "us-east-1"
  access_key = "AKIATKZIA3FTGO6J42FU"
  secret_key = "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"
}