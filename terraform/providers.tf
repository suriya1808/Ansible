# Tells Terraform which plugins (providers) to download.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Credentials are read automatically, e.g. from "aws login"
# or the AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY environment variables.
provider "aws" {
  region = var.region
}
