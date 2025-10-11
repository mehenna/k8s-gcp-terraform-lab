provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = file(var.credentials_file)
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

  source_ranges = ["10.0.0.0/16"]
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