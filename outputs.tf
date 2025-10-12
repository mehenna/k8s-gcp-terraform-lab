output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "subnet_a_id" {
  value = google_compute_subnetwork.subnet-a.id
}

output "subnet_b_id" {
  value = google_compute_subnetwork.subnet-b.id
}

output "k8s_node_role_ip_map" {
  description = "Mapping of Kubernetes roles to public IPs"
  value = merge(
    {
      control_plane = google_compute_instance.control_plane.network_interface[0].access_config[0].nat_ip
    },
    {
      for idx, node in google_compute_instance.workers :
      "worker_${idx + 1}" => node.network_interface[0].access_config[0].nat_ip
    }
  )
}

output "k8s_node_ips" {
  description = "List of all Kubernetes node public IPs"
  value = concat(
    [google_compute_instance.control_plane.network_interface[0].access_config[0].nat_ip],
    [for node in google_compute_instance.workers : node.network_interface[0].access_config[0].nat_ip]
  )
}