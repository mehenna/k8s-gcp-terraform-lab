provider "google" {
  project = var.project_id
  region  = var.region
  # Will use gcloud credentials automatically : 
  #  export GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token)
}

resource "google_compute_network" "vpc" {
  name                    = "tf-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet-a" {
  name          = "tf-subnet-a"
  ip_cidr_range = "9.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "subnet-b" {
  name          = "tf-subnet-b"
  ip_cidr_range = "9.0.2.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "allow-internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "all"
  }

  source_ranges = [
    google_compute_subnetwork.subnet-a.ip_cidr_range,
    google_compute_subnetwork.subnet-b.ip_cidr_range
  ]
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Kubernetes API Server access from external
resource "google_compute_firewall" "allow-k8s-api" {
  name    = "allow-k8s-api"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["control-plane"]
}

# Kubernetes cluster internal communication
resource "google_compute_firewall" "allow-k8s-cluster" {
  name    = "allow-k8s-cluster"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["6443", "10250", "2379-2380", "30000-32767"]
  }

  source_tags = ["k8s"]
  target_tags = ["k8s"]
}

# === Modern TCP Load Balancer for Kubernetes API Server ===

# Static IP for the load balancer
resource "google_compute_address" "k8s_api_lb_ip" {
  name   = "k8s-api-lb-ip"
  region = var.region
}

# Modern health check with proper TCP support (regional)
resource "google_compute_region_health_check" "k8s_api" {
  name                = "k8s-api-health-check"
  region              = var.region
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = 6443
  }
}

# Instance groups for control plane nodes (one per zone)
resource "google_compute_instance_group" "control_plane" {
  for_each    = toset(local.available_zones)
  name        = "k8s-control-plane-ig-${split("-", each.key)[2]}"  # Extract zone letter (a, b, c)
  description = "Instance group for Kubernetes control plane nodes in ${each.key}"
  zone        = each.key
  network     = google_compute_network.vpc.id

  # Add control plane instances that belong to this zone
  instances = [
    for name, instance in google_compute_instance.control_plane : 
    instance.self_link if instance.zone == each.key
  ]

  named_port {
    name = "k8s-api"
    port = 6443
  }
}

# Regional backend service
resource "google_compute_region_backend_service" "k8s_api" {
  name                  = "k8s-api-backend-service"
  region                = var.region
  protocol              = "TCP"
  load_balancing_scheme = "EXTERNAL"
  health_checks         = [google_compute_region_health_check.k8s_api.id]
  timeout_sec           = 10

  # Add all instance groups as backends
  dynamic "backend" {
    for_each = google_compute_instance_group.control_plane
    content {
      group          = backend.value.id
      balancing_mode = "CONNECTION"
    }
  }
}

# Forwarding rule (external entry point)
resource "google_compute_forwarding_rule" "k8s_api" {
  name                  = "k8s-api-forwarding-rule"
  region                = var.region
  ip_address            = google_compute_address.k8s_api_lb_ip.address
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "6443"
  backend_service       = google_compute_region_backend_service.k8s_api.id
}