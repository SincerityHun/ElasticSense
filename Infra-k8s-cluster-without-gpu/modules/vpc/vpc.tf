########################################
# 1. VARIABLES
########################################
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "subnet_cidr" {
  description = "values for the subnet CIDR"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "firewall_sources" {
  description = "List of source IP ranges for the firewall rules"
  type        = list(string)
}

variable "firewall_ports" {
  description = "List of ports to allow in the firewall rules"
  type        = list(string)
}
########################################
# 2. VPC Resources
########################################
resource "google_compute_network" "this" {
  name                    = var.vpc_name
  project                 = var.project_id
  routing_mode            = "REGIONAL"
  auto_create_subnetworks = false
}

########################################
# 3. Subnet Resources
########################################
resource "google_compute_subnetwork" "this" {
  name                     = var.subnet_name
  ip_cidr_range            = var.subnet_cidr
  network                  = google_compute_network.this.self_link
  region                   = var.region
  project                  = var.project_id
  private_ip_google_access = true
}

########################################
# 4. Firewall Rules
########################################
resource "google_compute_firewall" "this" {
  name = "${var.vpc_name}-fw"
  network = google_compute_network.this.self_link
  allow {
    protocol = "tcp"
    ports = var.firewall_ports
  }
  source_ranges = var.firewall_sources
  description   = "Allow required ports for SSH, Kubeflow, NFS, etc."
}
########################################
# 5. Output Variables
########################################
output "vpc_self_link" {
  description = "Self link of the VPC"
  value       = google_compute_network.this.self_link
}
output "subnet_self_link" {
  description = "Self link of the subnet"
  value       = google_compute_subnetwork.this.self_link
  
}
output "firewall_self_link" {
  description = "Self link of the firewall rule"
  value       = google_compute_firewall.this.self_link
  
}