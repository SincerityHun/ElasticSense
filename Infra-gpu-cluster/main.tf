terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.33.0"
    }

    kubernetes = {
        source  = "hashicorp/kubernetes"
        version = "~> 2.20.0"
    }

    helm ={
        source = "hashicorp/helm"
        version = "~> 2.10.0"
    }
  }
}
