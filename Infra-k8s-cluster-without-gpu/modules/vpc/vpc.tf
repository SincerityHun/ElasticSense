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
variable "firewall_rules" { # 사용자 추가 firewall_rules
  description = "Map of firewall rules with their configurations"
  type = map(object({
    protocol         = string
    ports            = optional(list(string))
    priority         = string
    description      = string
    tags             = optional(list(string))
    source_ip_ranges = optional(list(string))
  }))
  default = {}
}
variable "default_firewall_rules_enabled" { # default
  description = "If true, default firewall rules will be added to the firewall rules"
  type        = bool
  default     = true
}

#####################################
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
# 4. Advanced Firewall Rules 
# https://kbrzozova.medium.com/basic-firewall-rules-configuration-in-gcp-using-terraform-a87d268fa84f
########################################
locals {
  default_firewall_rules = var.default_firewall_rules_enabled ? tomap({
    # ICMP Rule - Allow all ICMP traffic(ping)
    "allow-icmp" = {
      protocol         = "icmp"
      ports            = []
      tags             = []
      priority         = "65534"
      description      = "Allow ICMP."
      source_ip_ranges = ["0.0.0.0/0"]
    }

    # SSH Rule - Allow SSH traffic
    "allow-ssh" = {
      protocol    = "tcp"
      ports       = ["22"]
      tags       =  []
      priority    = "1000"
      description = "Allow SSH communication via VPN."
      source_ip_ranges = [
        # "160.16.0.0/24",
        # "160.16.1.0/24",
        # "160.16.3.0/24"
        "0.0.0.0/0"
      ]
    }

    # HTTPS Imperva Rule
    # "allow-https-imperva" = {
    #   protocol         = "tcp"
    #   ports            = ["443"]
    #   priority         = "1000"
    #   tags             = ["https-imperva"]
    #   description      = "Allow http & https communication only via Imperva."
    #   source_ip_ranges = [
    #     "199.83.128.0/21",
    #     "149.126.72.0/21",
    #     "103.28.248.0/22",
    #     "45.64.64.0/22",
    #     "185.11.124.0/22",
    #     "192.230.64.0/18",
    #     "107.154.0.0/16",
    #     "45.60.0.0/16",
    #     "45.223.0.0/16"
    #   ]
    # }

    # HTTPS VPN Rule
    # "allow-https-vpn" = {
    #   protocol         = "tcp"
    #   ports            = ["443"]
    #   priority         = "1000"
    #   tags             = ["https-vpn"]
    #   description      = "Allow https communication via VPN."
    #   source_ip_ranges = [
    #     "172.16.0.0/24",
    #     "172.16.1.0/24",
    #     "172.16.3.0/24"
    #   ]
    # }

    # Cross-Project Communication Rules
    # "allow-example" = {
    #   protocol         = "all"
    #   priority         = "1000"
    #   description      = "Allow communication from Example project - hello VPC."
    #   source_ip_ranges = ["10.200.0.0/16"]
    # }
  }) : tomap({})

  # Merge custom firewall rules with default ones
  # Custom rules will override default rules with the same key
  all_firewall_rules = merge(local.default_firewall_rules, var.firewall_rules)
}
resource "google_compute_firewall" "this" {
  for_each = local.all_firewall_rules

  project     = var.project_id
  name        = "${var.vpc_name}-${each.key}"
  network     = google_compute_network.this.self_link
  description = each.value.description
  priority    = each.value.priority
  target_tags = lookup(each.value, "tags", null)

  dynamic "allow" {
    for_each = each.value.protocol != "all" ? [1] : []
    content {
      protocol = each.value.protocol
      ports    = lookup(each.value, "ports", null)
    }
  }

  dynamic "allow" {
    for_each = each.value.protocol == "all" ? [1] : []
    content {
      protocol = each.value.protocol
    }
  }

  source_ranges = try(each.value.source_ip_ranges, [])
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
  value = {
    for k, v in google_compute_firewall.this :
    k => v.self_link
  }

}
