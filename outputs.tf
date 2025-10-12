output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "subnet_a_id" {
  value = google_compute_subnetwork.subnet-a.id
}

output "subnet_b_id" {
  value = google_compute_subnetwork.subnet-b.id
}

# Mapping of roles → public IPs
output "k8s_node_role_ip_map" {
  description = "Mapping of Kubernetes node roles to their public IPs"
  value = merge(
    {
      control-plane = google_compute_instance.control_plane.network_interface[0].access_config[0].nat_ip
    },
    {
      for role, node in google_compute_instance.workers :
      role => node.network_interface[0].access_config[0].nat_ip
    }
  )
}

# List of all node IPs
output "k8s_node_ips" {
  description = "List of all Kubernetes node public IPs"
  value = concat(
    [google_compute_instance.control_plane.network_interface[0].access_config[0].nat_ip],
    [for node in google_compute_instance.workers : node.network_interface[0].access_config[0].nat_ip]
  )
}
