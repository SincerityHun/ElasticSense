########################################
# 1. Project SSH Key 생성
########################################
resource "google_compute_project_metadata" "default" {
  project = var.project_id
  metadata = {
    "ssh-keys" = "${file(var.ssh_user)}:${file(var.ssh_public_key_path)}"
  }
}
########################################
# 2. 인스턴스 생성
########################################
# (1) k8s-master
resource "google_compute_instance" "k8s_master" {
  name         = "k8s-master"
  machine_type = var.compute_machine_type[0]
  zone         = var.zone
  project      = var.project_id

  # VPC
  network_interface {
    subnetwork = module.vpc.subnet_self_link
    access_config {

    }
  }

  # Boot Disk
  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20240125"
      size  = 100
      type  = "pd-standard"
    }
  }

  #   metadata_startup_script = file("scripts/k8s-master-startup.sh")
  # TAG
  tags = ["k8s-master", "kubeflow"]
  # 1. File Copy for nfs client
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
    source      = "${path.root}/scripts/setup_nfs_client.sh"
    destination = "/tmp/setup_nfs_client.sh"
  }
  # 2. File Copy for setup k8s master
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
    source      = "${path.root}/scripts/setup_k8s_master.sh"
    destination = "/tmp/setup_k8s_master.sh"
  }

  # 3. Remote exec for k8s cluster
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
    inline = [
      # Set disable
      "sudo systemctl disable --now apt-daily.timer",
      "sudo systemctl disable --now apt-daily-upgrade.timer",
      "sudo systemctl mask apt-daily.timer",
      "sudo systemctl mask apt-daily-upgrade.timer",
      # Set NFS Client
      "export NFS_SERVER_IP=${google_compute_instance.nfs_server.network_interface[0].network_ip}",
      "chmod +x /tmp/setup_nfs_client.sh",
      "/tmp/setup_nfs_client.sh",
      # Set K8s Master
      "chmod +x /tmp/setup_k8s_master.sh",
      "/tmp/setup_k8s_master.sh",
      "mkdir -p /tmp/setup_modules",
    ]
  }

  depends_on = [google_compute_instance.nfs_server]
}
# (2) k8s-worker0
resource "google_compute_instance" "k8s_worker0" {
  name         = "k8s-worker0"
  machine_type = var.compute_machine_type[1]
  zone         = var.zone

  network_interface {
    subnetwork = module.vpc.subnet_self_link
    access_config {}
  }

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20240125"
      size  = 100
      type  = "pd-standard"
    }
  }

  tags = ["kubeflow"]
  # 1. File Copy for nfs client
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
    source      = "${path.root}/scripts/setup_nfs_client.sh"
    destination = "/tmp/setup_nfs_client.sh"
  }
  # 2. File Copy for setup k8s worker
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
    source      = "${path.root}/scripts/setup_k8s_worker.sh"
    destination = "/tmp/setup_k8s_worker.sh"
  }
  # 3. Remote exec
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
    inline = [
      # Set disable
      "sudo systemctl disable --now apt-daily.timer",
      "sudo systemctl disable --now apt-daily-upgrade.timer",
      "sudo systemctl mask apt-daily.timer",
      "sudo systemctl mask apt-daily-upgrade.timer",
      # Set NFS Client
      "export NFS_SERVER_IP=${google_compute_instance.nfs_server.network_interface[0].network_ip}",
      "chmod +x /tmp/setup_nfs_client.sh",
      "/tmp/setup_nfs_client.sh",
      # Set K8s Worker
      "chmod +x /tmp/setup_k8s_worker.sh",
      "/tmp/setup_k8s_worker.sh",
    ]
  }
  depends_on = [google_compute_instance.nfs_server, google_compute_instance.k8s_master]
}

# (3) nfs-server
resource "google_compute_disk" "nfs_data_disk" {
  name = "nfs-data-disk"
  type = "pd-standard"
  size = 50
  zone = var.zone
}
resource "google_compute_instance" "nfs_server" {
  name         = "nfs-server"
  machine_type = var.compute_machine_type[2]
  zone         = var.zone

  network_interface {
    subnetwork = module.vpc.subnet_self_link
    access_config {
      # nat_ip = google_compute_address.nfs_server_ip.address
    }
  }

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20240125"
      size  = 10
      type  = "pd-standard"
    }
  }

  # External disk
  attached_disk {
    source = google_compute_disk.nfs_data_disk.id
  }

  tags = ["kubeflow"]

  # setup NFS server
  metadata_startup_script = file("${path.root}/scripts/setup_nfs_server.sh")
}

# (4) Setup modules
resource "null_resource" "kubeflow" {
  depends_on = [google_compute_instance.k8s_master, google_compute_instance.k8s_worker0, google_compute_instance.nfs_server]
  # 1. File Copy for setup modules
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = google_compute_instance.k8s_master.network_interface[0].access_config[0].nat_ip
    }
    source      = "${path.root}/scripts/setup_modules/"
    destination = "/tmp/setup_modules"
  }
  # 2. Remote exec for setup kubeflow
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = google_compute_instance.k8s_master.network_interface[0].access_config[0].nat_ip
    }
    inline = [
      # Pretest K8s Cluster
      "chmod +x /tmp/setup_modules/pretest_k8s_cluster.sh",
      "/tmp/setup_modules/pretest_k8s_cluster.sh",
      # NFS_External Provisioner Setup
      "export NFS_SERVER_IP=${google_compute_instance.nfs_server.network_interface[0].network_ip}",
      "chmod +x /tmp/setup_modules/nfs_external_provisioner/setup_nfs_external_provisioner.sh",
      "/tmp/setup_modules/nfs_external_provisioner/setup_nfs_external_provisioner.sh",
      # Kustomize Setup
      "chmod +x /tmp/setup_modules/kustomize/setup_kustomize.sh",
      "/tmp/setup_modules/kustomize/setup_kustomize.sh",
      # Kubeflow Setup
      "chmod +x /tmp/setup_modules/kubeflow/setup_kubeflow.sh",
      "/tmp/setup_modules/kubeflow/setup_kubeflow.sh",
      # Prometheus Stack Setup
      "chmod +x /tmp/setup_modules/prometheus-stack/setup_prometheus.sh",
      "/tmp/setup_modules/prometheus-stack/setup_prometheus.sh",
      # MPI Operator Setup
      # "chmod +x /tmp/setup_modules/mpi-operator/setup_mpi-operator.sh",
      # "/tmp/setup_modules/mpi-operator/setup_mpi-operator.sh",
    ]
  }
  # 3. fetch kubeconfig
  # provisioner "local-exec"{
  #   command = <<EOT
  #     scp -i ${var.ssh_private_key_path} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  #     ${var.ssh_user}@${google_compute_instance.k8s_master.network_interface[0].access_config[0].nat_ip}:/home/${file(var.ssh_user)}/.kube/config \
  #     ${path.root}/kubeconfig
  #     sed -ie "s|server: https://.*|server: https://${google_compute_instance.k8s_master.network_interface[0].access_config[0].nat_ip}:6443|g" ${path.root}/kubeconfig
  #     export KUBECONFIG=${path.root}/kubeconfig
  #   EOT
  # }
}
