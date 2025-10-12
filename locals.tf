locals {
  # Node roles - consider making this configurable via variables
  node_roles = ["worker-1", "worker-2"]

  # Base configuration
  region = "europe-west9"
  
  # Dynamic zone mapping based on region
  available_zones = ["${local.region}-a", "${local.region}-b", "${local.region}-c"]
  
  # Subnet mapping per role
  subnet_map = {
    worker-1 = google_compute_subnetwork.subnet-a.id
    worker-2 = google_compute_subnetwork.subnet-b.id
  }

  # Zone mapping per role - now dynamic
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