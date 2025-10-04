output "project_id" {
  description = "The project ID"
  value       = module.project.project_id
}

output "project_number" {
  description = "The project number"
  value       = module.project.number
}

output "firestore_database" {
  description = "The Firestore database"
  value       = module.firestore.firestore_database.name
}

output "region" {
  description = "The deployment region"
  value       = var.region
}

output "backend_url" {
  description = "The URL of the backend Cloud Run service"
  value       = module.cloud_run_backend.service.uri
}
