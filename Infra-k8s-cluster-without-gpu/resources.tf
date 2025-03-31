########################################
# 3. NFS 서버용 고정 IP 생성
########################################
resource "google_compute_address" "nfs_server_ip" {
  name    = "nfs-server-ip"
  region  = var.region
  project = var.project_id
}

########################################
# 4. 인스턴스 생성
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
}
