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