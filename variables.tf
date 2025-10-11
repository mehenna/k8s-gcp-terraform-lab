variable "project_id" {
  description = "GCP project ID"
  type        = string
  # Set this value in terraform.tfvars or via environment variable TF_VAR_project_id
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west9"
}

variable "credentials_file" {
  description = "Path to the GCP service account JSON key"
  type        = string
  default     = "./terraform-admin.json"
}

