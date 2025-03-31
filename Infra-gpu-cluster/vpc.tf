module "vpc" {
    source = "terraform-aws-modules/vpc/aws"
    version = "~> 4.0"
    name = "${var.cluster_name}-vpc"
    cidr = "10.0.0.0/16"

    azs = ["${var.region}a", "${var.region}b", "${var.region}c"]
    private_subnets = ["10.0.1.0/24","10.0.2.0/24"]
    public_subnets = ["10.0.101.0/24","10.0.102.0/24"]

    enable_nat_gateway = true
    single_nat_gateway = true
    enable_dns_hostnames = true

    tags = {
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
    public_subnet_tags = {
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        "kubernetes.io/role/elb" = "1"
    }
    private_subnet_tags = {
        "kubernetes.io/cluster/${var.cluster_name}" = "shared"
        "kubernetes.io/role/internal-elb" = "1"
    }
}