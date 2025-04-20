terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google={
        source = "hashicorp/google"
        version = ">= 4.0"
    }
  }
}

########################################
# 1. VPC 모듈 호출
########################################
module "vpc"{
  source = "./modules/vpc"
  vpc_name = var.vpc_name
  subnet_name = var.subnet_name
  subnet_cidr = var.subnet_cidr
  project_id = var.project_id
  region = var.region
  default_firewall_rules_enabled = var.default_firewall_rules_enabled
  firewall_rules = var.firewall_rules
}