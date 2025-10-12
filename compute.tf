# === Instance Template for Kubernetes Nodes ===
resource "google_compute_instance_template" "k8s_node_template" {
  name_prefix   = "k8s-node-"
  machine_type  = "e2-medium"
  region        = var.region
  can_ip_forward = true

  tags = ["k8s", "node"]

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2204-lts"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet-a.id
    access_config {}
  }

  service_account {
    email  = "k8s-nodes@${var.project_id}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}


# === Control Plane Node (Static) ===
resource "google_compute_instance" "control_plane" {
  name         = "k8s-control-plane"
  machine_type = "e2-medium"
  zone         = "europe-west9-a"
  tags         = ["k8s", "control-plane"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet-a.id
    access_config {}
  }

  service_account {
    email  = "k8s-nodes@${var.project_id}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# === Worker Nodes (Dynamic) ===

resource "google_compute_instance" "workers" {
  count        = var.worker_count
  name         = "k8s-worker-${count.index + 1}"
  machine_type = "e2-medium"
  zone         = count.index == 0 ? "europe-west9-a" : "europe-west9-b"
  tags         = ["k8s", "worker"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = count.index == 0 ? google_compute_subnetwork.subnet-a.id : google_compute_subnetwork.subnet-b.id
    access_config {}
  }

  service_account {
    email  = "k8s-nodes@${var.project_id}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}