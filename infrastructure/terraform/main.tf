terraform {
  backend "s3" {
    key    = "blog"
    region = "us-west-2"
  }
  required_version = ">= 0.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.4"
    }
  }
}

provider "aws" {
  region = var.region
}


provider "aws" {
  region = "us-east-1"
  alias  = "aws_cloudfront"
}

data "aws_caller_identity" "current" {}