locals {
  # Control plane nodes for HA (minimum 3 for etcd quorum)
  control_plane_nodes = ["control-plane-1", "control-plane-2", "control-plane-3"]
  
  # Worker node roles
  node_roles = ["worker-1", "worker-2"]

  # Base configuration
  region = "europe-west9"
  
  # Dynamic zone mapping based on region
  available_zones = ["${local.region}-a", "${local.region}-b", "${local.region}-c"]
  
  # Subnet mapping for control planes (distribute across zones)
  control_plane_config = {
    control-plane-1 = {
      zone   = local.available_zones[0]
      subnet = google_compute_subnetwork.subnet-a.id
    }
    control-plane-2 = {
      zone   = local.available_zones[1]
      subnet = google_compute_subnetwork.subnet-b.id
    }
    control-plane-3 = {
      zone   = local.available_zones[2]
      subnet = google_compute_subnetwork.subnet-a.id
    }
  }
  
  # Subnet mapping per worker role
  subnet_map = {
    worker-1 = google_compute_subnetwork.subnet-a.id
    worker-2 = google_compute_subnetwork.subnet-b.id
  }

  # Zone mapping per worker role
  zone_map = {
    worker-1 = local.available_zones[0]
    worker-2 = local.available_zones[1]
  }

  # Additional useful mappings
  node_config = {
    for role in local.node_roles : role => {
      subnet = local.subnet_map[role]
      zone   = local.zone_map[role]
    }
  }

  # Validation - ensure all roles have corresponding subnets and zones
  validation_check = {
    subnet_roles_match = length(keys(local.subnet_map)) == length(local.node_roles)
    zone_roles_match   = length(keys(local.zone_map)) == length(local.node_roles)
  }
}