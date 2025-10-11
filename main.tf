terraform {
  required_version = ">= 1.5.0"

  # Uncomment and configure backend after creating your GCS bucket
  # backend "gcs" {
  #   bucket = "YOUR_TERRAFORM_STATE_BUCKET"
  #   prefix = "terraform/state"
  # }
}



