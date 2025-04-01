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
# 2. NFS 서버용 고정 IP 생성
########################################
resource "google_compute_address" "nfs_server_ip" {
  name    = "nfs-server-ip"
  region  = var.region
  project = var.project_id
}

########################################
# 3. 인스턴스 생성
########################################
# (1) k8s-master
resource "google_compute_instance" "k8s_master" {
  name         = "k8s-master"
  machine_type = "e2-standard-8"
  zone         = var.zone
  project      = var.project_id

  # VPC
  network_interface {
    subnetwork    = module.vpc.subnet_self_link
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
  # 1. File Copy
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
    source = "${path.root}/scripts/setup_nfs_client.sh"
    destination = "/tmp/setup_nfs_client.sh"
  }
  # 2. Remote exec
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
    inline = [ 
      "export NFS_SERVER_IP=${google_compute_address.nfs_server_ip.address}",
      "chmod +x /tmp/setup_nfs_client.sh",
      "/tmp/setup_nfs_client.sh" # NFS Client Setup
     ]
  }
  depends_on = [ google_compute_instance.nfs_server ]
}
# (2) k8s-worker0
resource "google_compute_instance" "k8s_worker0" {
  name         = "k8s-worker0"
  machine_type = "e2-standard-4"
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
  # 1. File Copy
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
    source = "${path.root}/scripts/setup_nfs_client.sh"
    destination = "/tmp/setup_nfs_client.sh"
  }
  # 2. Remote exec
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
    inline = [ 
      "export NFS_SERVER_IP=${google_compute_address.nfs_server_ip.address}",
      "chmod +x /tmp/setup_nfs_client.sh",
      "/tmp/setup_nfs_client.sh" # NFS Client Setup
     ]
  }
  depends_on = [ google_compute_instance.nfs_server, google_compute_instance.k8s_master ]
}
# (3) k8s-worker1
resource "google_compute_instance" "k8s_worker1" {
  name         = "k8s-worker1"
  machine_type = "e2-standard-4"
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
  # 1. File Copy
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
    source = "${path.root}/scripts/setup_nfs_client.sh"
    destination = "/tmp/setup_nfs_client.sh"
  }
  # 2. Remote exec
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
    inline = [ 
      "export NFS_SERVER_IP=${google_compute_address.nfs_server_ip.address}",
      "chmod +x /tmp/setup_nfs_client.sh",
      "/tmp/setup_nfs_client.sh" # NFS Client Setup
     ]
  }
  depends_on = [ google_compute_instance.nfs_server, google_compute_instance.k8s_master ]
}

# (4) k8s-worker2
resource "google_compute_instance" "k8s_worker2" {
  name         = "k8s-worker2"
  machine_type = "e2-standard-4"
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
  # 1. File Copy
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
    source = "${path.root}/scripts/setup_nfs_client.sh"
    destination = "/tmp/setup_nfs_client.sh"
  }
  # 2. Remote exec
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = file(var.ssh_user)
      private_key = file(var.ssh_private_key_path)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
    inline = [ 
      "export NFS_SERVER_IP=${google_compute_address.nfs_server_ip.address}",
      "chmod +x /tmp/setup_nfs_client.sh",
      "/tmp/setup_nfs_client.sh" # NFS Client Setup
     ]
  }
  depends_on = [ google_compute_instance.nfs_server, google_compute_instance.k8s_master ]
}

# (5) nfs-server
resource "google_compute_disk" "nfs_data_disk" {
  name  = "nfs-data-disk"
  type  = "pd-standard"
  size  = 50
  zone  = var.zone
}
resource "google_compute_instance" "nfs_server" {
  name         = "nfs-server"
  machine_type = "e2-standard-2" # 필요한 사양에 맞춰 조정
  zone         = var.zone

  network_interface {
    subnetwork = module.vpc.subnet_self_link
    # 고정 IP 할당
    access_config {
      nat_ip = google_compute_address.nfs_server_ip.address
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
