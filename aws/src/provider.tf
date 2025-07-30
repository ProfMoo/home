terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.2.0"
    }
  }
  backend "s3" {
    bucket = "sobrien-home"
    key    = "home"
    region = "us-east-1"
    # To authenticate to access the state (not the actual terraform commands)
    shared_credentials_files = ["./aws-credentials"]
  }
}

provider "aws" {
  region = "us-east-2"
  # To authenticate to access during the plan/apply phase
  shared_credentials_files = ["./aws-credentials"]
}
