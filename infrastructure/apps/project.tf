module "project" {
  source          = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/project"
  billing_account = var.billing_account
  name            = var.project_id

  parent = "folders/${var.folder_id}"

  services = [
    # Core infrastructure
    "cloudresourcemanager.googleapis.com",
    "stackdriver.googleapis.com",
    "iam.googleapis.com",

    # Aura One backend services
    "aiplatform.googleapis.com",      # Vertex AI for Gemini 2.0 Flash
    "firestore.googleapis.com",       # Firestore for rate limiting
    "run.googleapis.com",             # Cloud Run for backend deployment
    "cloudbuild.googleapis.com",      # Cloud Build for containerization

    # Additional services
    "storage.googleapis.com",         # Cloud Storage
    "logging.googleapis.com",         # Cloud Logging
    "monitoring.googleapis.com",      # Cloud Monitoring
  ]
}
