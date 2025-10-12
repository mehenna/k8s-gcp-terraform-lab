terraform {
  required_version = ">= 1.5.0"

  # Backend configuration for remote state storage
  # The bucket name will be configured during terraform init
  backend "gcs" {
    # bucket = "configured-via-backend-config-file"
    prefix = "terraform/state"
  }
}



