# === Service Account ===
resource "google_service_account" "k8s_nodes" {
  account_id   = "k8s-nodes"
  display_name = "Kubernetes Node Service Account"
  project      = var.project_id

  depends_on = [google_project_service.iam]
}

# === IAM Bindings for Minimal Privileges ===
resource "google_project_iam_member" "compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.k8s_nodes.email}"
}

resource "google_project_iam_member" "storage_object_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.k8s_nodes.email}"
}

# === Service Account Key for Terraform Authentication ===
resource "google_service_account" "terraform_admin" {
  account_id   = "terraform-admin"
  display_name = "Terraform Admin Service Account"
  project      = var.project_id

  depends_on = [google_project_service.iam]
}

resource "google_project_iam_member" "terraform_admin_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.terraform_admin.email}"
}

resource "google_service_account_key" "terraform_admin_key" {
  service_account_id = google_service_account.terraform_admin.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# Save the service account key to a local file
resource "local_file" "terraform_admin_key" {
  content  = base64decode(google_service_account_key.terraform_admin_key.private_key)
  filename = "${path.module}/terraform-admin-key.json"
  file_permission = "0600"
}
