terraform {
  required_version = ">= 1.11.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.98.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.8.0"
    }
  }
}
