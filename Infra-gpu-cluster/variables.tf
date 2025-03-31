variable "cluster_name" {
  description = "Name of the EKS cluster"
  default = "test-gpu-cluster"
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use for the EKS cluster"
  default = "1.28"
}

variable "region" {
  description = "AWS region"
  default = "us-west-2"
}