# === Service Account ===
resource "google_service_account" "k8s_nodes" {
  account_id   = "k8s-nodes"
  display_name = "Kubernetes Node Service Account"
  project      = var.project_id
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
