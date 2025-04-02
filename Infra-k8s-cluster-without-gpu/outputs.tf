########################################
# 1. NFS Server IP
########################################
output "nfs_server_ip" {
  description = "NFS Server IP"
  value       = google_compute_address.nfs_server_ip.address
}

########################################
# 5. k8s-master external IP
########################################
output "k8s_master_external_ip" {
  value = google_compute_instance.k8s_master.network_interface[0].access_config[0].nat_ip
  description = "External IP of the Kubernetes master node"
}

output "k8s_worker0_external_ip" {
  value = google_compute_instance.k8s_worker0.network_interface[0].access_config[0].nat_ip
  description = "External IP of the Kubernetes worker0 node"
}

# output "k8s_worker1_external_ip" {
#   value = google_compute_instance.k8s_worker1.network_interface[0].access_config[0].nat_ip
#   description = "External IP of the Kubernetes worker1 node"
# }

# output "k8s_worker2_external_ip" {
#   value = google_compute_instance.k8s_worker2.network_interface[0].access_config[0].nat_ip
#   description = "External IP of the Kubernetes worker2 node"
# }

output "nfs_server_external_ip" {
  value = google_compute_instance.nfs_server.network_interface[0].access_config[0].nat_ip
  description = "External IP of the NFS server"
}
