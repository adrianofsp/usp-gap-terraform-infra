terraform {
  required_version = "~>1.2.2"
  backend "s3" {
    bucket = "terraform-state-047080362522"
    key    = "tf-workspaces/terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.16.0"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.region
}

module "instance_profile_label" {
  source  = "cloudposse/label/null"
  version = "0.22.1"

  attributes = distinct(compact(concat(module.this.attributes, ["profile"])))

  context = module.this.context
}