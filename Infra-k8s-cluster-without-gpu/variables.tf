variable "project_id" {
  description = "Project ID"
  default     = "elasticsense-455413"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "k8s-vpc"
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "k8s-subnet"
}

variable "subnet_cidr" {
  description = "values for the subnet CIDR"
  type        = string
  default = "10.10.0.0/20"
}

variable "firewall_sources" {
  description = "values for the firewall sources"
  type        = list(string)
  default = [ "0.0.0.0/0" ]
}

variable "firewall_ports" {
  description = "values for the firewall ports"
  type        = list(string)
  default = [ "22", "8080", "8081", "8082", "8888", "2049" ]
  
}

variable "ssh_user" {
  description = "SSH user"
  type        = string
  default     = "../keyfiles/.ssh/username"
}

variable "ssh_public_key_path" {
  description = "SSH public key path"
  type        = string
  default     = "../keyfiles/.ssh/google_compute_engine.pub"
}

variable "ssh_private_key_path" {
  description = "SSH private key path"
  type        = string
  default     = "../keyfiles/.ssh/google_compute_engine"
}