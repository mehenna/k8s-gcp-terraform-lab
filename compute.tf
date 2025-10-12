# === Instance Template for Kubernetes Nodes ===
resource "google_compute_instance_template" "k8s_node_template" {
  name_prefix    = "k8s-node-"
  machine_type   = "e2-medium"
  region         = var.region
  can_ip_forward = true

  tags = ["k8s", "node"]

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2204-lts"
    auto_delete  = true
    boot         = true
    disk_size_gb = 10  # Added for consistency
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet-a.id
    access_config {}
  }

  service_account {
    email  = google_service_account.k8s_nodes.email  # Reference instead of hardcoded
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  lifecycle {
    create_before_destroy = true
  }
}


# === Control Plane Node (Static) ===
resource "google_compute_instance" "control_plane" {
  name         = "k8s-control-plane"
  machine_type = "e2-medium"
  zone         = local.zone_map["worker-1"]  # Use locals for consistency
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
    email  = google_service_account.k8s_nodes.email  # Reference instead of hardcoded
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}

# === Worker Nodes (Dynamic) ===
resource "google_compute_instance" "workers" {
  for_each     = toset(local.node_roles)
  name         = "k8s-${each.key}"
  machine_type = "e2-medium"
  zone         = local.zone_map[each.key]
  tags         = ["k8s", "worker", each.key]  # Added role-specific tag

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 10
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = local.subnet_map[each.key]
    access_config {}
  }

  service_account {
    email  = google_service_account.k8s_nodes.email  # Reference instead of hardcoded
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  # Allow recreation during updates
  lifecycle {
    create_before_destroy = true
  }
}