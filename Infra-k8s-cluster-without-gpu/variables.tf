variable "project_id" {
  description = "Project ID"
  default     = "elasticsense-455413"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "asia-northeast3-a"
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
  default     = "10.10.0.0/20"
}

variable "default_firewall_rules_enabled" {
  description = "If true, default firewall rules will be added to the firewall rules"
  type        = bool
  default     = true
  
}
variable "firewall_rules" { # 사용자 추가 firewall_rules
  description = "Map of firewall rules which is user customized"
  type        = map(object({
    protocol         = string
    ports            = optional(list(string))
    priority         = string
    description      = string
    tags             = optional(list(string))
    source_ip_ranges = optional(list(string))
  }))
  default = {}
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

variable "compute_machine_type" {
  description = "Compute machine type"
  type        = list(string)
  default     = ["e2-standard-8", "e2-standard-4", "e2-standard-2"] # k8s-master, k8s-node, nfs-server
}
