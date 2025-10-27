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
      for name, instance in google_compute_instance.control_plane :
      name => instance.network_interface[0].access_config[0].nat_ip
    },
    {
      for role, node in google_compute_instance.workers :
      role => node.network_interface[0].access_config[0].nat_ip
    }
  )
}

# Service account information
output "terraform_admin_service_account_email" {
  description = "Email of the Terraform admin service account"
  value       = google_service_account.terraform_admin.email
}

output "terraform_admin_key_file" {
  description = "Path to the generated Terraform admin service account key file"
  value       = local_file.terraform_admin_key.filename
}

# Network configuration
output "subnet_cidrs" {
  description = "CIDR ranges of the subnets"
  value = {
    subnet_a = google_compute_subnetwork.subnet-a.ip_cidr_range
    subnet_b = google_compute_subnetwork.subnet-b.ip_cidr_range
  }
}

# List of all node IPs
output "k8s_node_ips" {
  description = "List of all Kubernetes node public IPs"
  value = concat(
    [for instance in google_compute_instance.control_plane : instance.network_interface[0].access_config[0].nat_ip],
    [for node in google_compute_instance.workers : node.network_interface[0].access_config[0].nat_ip]
  )
}

# Control plane IPs (for easy reference)
output "k8s_control_plane_ips" {
  description = "Map of control plane nodes to their public IPs"
  value = {
    for name, instance in google_compute_instance.control_plane :
    name => instance.network_interface[0].access_config[0].nat_ip
  }
}

# Load Balancer IP for Kubernetes API
output "k8s_api_lb_ip" {
  description = "Load balancer IP for Kubernetes API server (use this for kubeadm init)"
  value       = google_compute_address.k8s_api_lb_ip.address
}

# Internal Load Balancer IP for Kubernetes API (for HA within VPC)
output "k8s_api_internal_lb_ip" {
  description = "Internal load balancer IP for Kubernetes API server (use this for node-to-API communication)"
  value       = google_compute_address.k8s_api_internal_lb_ip.address
}
