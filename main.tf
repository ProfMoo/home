terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = "us-east-2"
  profile    = "default"
  
  shared_credentials_file = "/aws-credentials"
}

resource "aws_instance" "ubuntu" {
  # NOTE: Ubuntu 20.10 us-east-1 amd64 image
  ami               = "ami-019212a8baeffb0fa"
  instance_type     = "t3a.micro"
  availability_zone = "us-east-2a"
}

# use rsync to sync between local linux raid and amazon backup (ec2 and ebs)
# use ntf to sync between roon core and the local linux raid
