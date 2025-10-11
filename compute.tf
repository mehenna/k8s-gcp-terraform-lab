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

# === Three VM instances ===
resource "google_compute_instance" "k8s_nodes" {
  count        = 3
  name         = "k8s-node-${count.index + 1}"
  zone         = "europe-west9-a"
  machine_type = "e2-medium"

  tags = ["k8s", "node"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
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
