output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "subnet_a_id" {
  value = google_compute_subnetwork.subnet-a.id
}

output "subnet_b_id" {
  value = google_compute_subnetwork.subnet-b.id
}

output "node_ips" {
  value = [for node in google_compute_instance.k8s_nodes : node.network_interface[0].access_config[0].nat_ip]
}

