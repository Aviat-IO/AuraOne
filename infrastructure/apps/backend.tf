terraform {
  backend "gcs" {}
}

locals {
  backend_app_name = "aura-one-backend"
  # Use absolute path to avoid issues with Terragrunt cache directory
  backend_app_dir = "/Users/alancolver/dev/auraone/backend"

  # Only track actual source code that affects the build
  backend_source_patterns = [
    "src/**/*.{ts,js}",
    "package.json",
    "bun.lockb",
    "tsconfig.json",
    "Dockerfile",
    "cloudbuild.yaml",
    ".dockerignore"
  ]

  # Efficient hash calculation - only files that actually matter
  backend_content_hash = md5(join("", flatten([
    for pattern in local.backend_source_patterns : [
      for f in try(fileset(local.backend_app_dir, pattern), []) :
      can(filemd5("${local.backend_app_dir}/${f}")) ? filemd5("${local.backend_app_dir}/${f}") : ""
    ]
  ])))

  terraform_config_hash = filemd5("${path.module}/backend.tf")

  # Combine content hash with terraform config for complete rebuild trigger
  combined_hash = md5("${local.backend_content_hash}-${local.terraform_config_hash}")

  # Use the combined hash as the image tag to ensure Cloud Run updates
  image_tag = local.combined_hash

  # Get git commit for reference (used in labels, not image tag)
  git_commit_hash = trimspace(try(data.external.git_commit[0].result.commit_hash, "unknown"))
}

# Data source to get the latest git commit hash
data "external" "git_commit" {
  count   = 1
  program = ["bash", "-c", "echo '{\"commit_hash\": \"'$(git rev-parse HEAD 2>/dev/null || echo unknown)'\"}'"]
}

# Artifact Registry for Docker images
module "artifact_registry" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/artifact-registry"
  project_id = module.project.project_id
  location   = var.region
  name       = "aura-one-images"
  format     = { docker = { standard = {} } }
}

# Build and push the backend image when source files change
resource "null_resource" "build_and_push_backend" {
  triggers = {
    # Use the same hash for both triggering and image tagging
    combined_hash = local.combined_hash
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      echo "Combined hash: ${self.triggers.combined_hash}"
      echo "Git commit: ${local.git_commit_hash}"

      BUILD_TAG=${var.region}-docker.pkg.dev/${module.project.project_id}/${module.artifact_registry.name}/${local.backend_app_name}:${local.image_tag}

      echo "Building image via Cloud Build: $BUILD_TAG"

      # Ensure we're authenticated with gcloud
      gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -1 > /dev/null || gcloud auth login

      # Use Cloud Build to build and push the image
      gcloud builds submit ${local.backend_app_dir} \
        --project=${module.project.project_id} \
        --config=${local.backend_app_dir}/cloudbuild.yaml \
        --substitutions=_IMAGE_TAG=$BUILD_TAG

      echo "Cloud Build completed successfully!"

      # Wait a moment for the image to be available
      sleep 10

      # Verify the image exists in Artifact Registry
      gcloud artifacts docker images describe $BUILD_TAG --format="value(name)" || {
        echo "ERROR: Image not found in Artifact Registry after push"
        exit 1
      }

      echo "Image verified in Artifact Registry"
    EOT
    interpreter = ["bash", "-c"]
  }

  depends_on = [module.artifact_registry]
}

# Service account for the backend Cloud Run service
module "backend_service_account" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/iam-service-account"
  project_id   = module.project.project_id
  name         = "backend-service"
  display_name = "Backend Service Account"
  description  = "Service account for Backend Cloud Run service"

  # Grant necessary roles for the backend service
  iam_project_roles = {
    "${module.project.project_id}" = [
      "roles/aiplatform.user",           # Access Vertex AI
      "roles/datastore.user",            # Access Firestore
      "roles/logging.logWriter",         # Write logs
      "roles/cloudtrace.agent",          # Trace
      "roles/monitoring.metricWriter",   # Metrics
    ]
  }
}

# Cloud Run service for the backend
module "cloud_run_backend" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/cloud-run-v2"
  project_id = module.project.project_id
  name       = local.backend_app_name
  region     = var.region

  service_account = module.backend_service_account.email

  containers = {
    backend = {
      image = "${module.artifact_registry.url}/${local.backend_app_name}:${local.image_tag}"
      ports = {
        default = {
          container_port = 5566
        }
      }
      # Runtime environment variables
      env = {
        GCP_PROJECT_ID = module.project.project_id
        GCP_LOCATION   = var.region
        NODE_ENV       = var.env == "prod" ? "production" : "development"
        # Force revision update when code changes
        DEPLOYMENT_HASH = local.image_tag
      }
      resources = {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
        startup_cpu_boost = true
      }
    }
  }

  service_config = {
    max_instance_count = var.env == "prod" ? 10 : 3
    min_instance_count = var.env == "prod" ? 1 : 0
  }

  revision = {
    # Force new revision when image changes
    annotations = {
      "deployment.hash" = local.image_tag
      "git.commit"      = local.git_commit_hash
    }
  }

  # Note: If organization policy blocks allUsers, manually grant roles/run.invoker to allUsers
  # via gcloud: gcloud run services add-iam-policy-binding aura-one-backend --region=us-central1 --member=allUsers --role=roles/run.invoker
  iam = {}

  labels = var.labels

  deletion_protection = var.deletion_protection

  depends_on = [
    null_resource.build_and_push_backend,
    module.backend_service_account,
    module.firestore
  ]
}

# Automatically update traffic to latest revision after deployment
resource "null_resource" "update_backend_traffic" {
  triggers = {
    # Trigger when the image changes
    image_tag  = local.image_tag
    service_id = module.cloud_run_backend.id
  }

  provisioner "local-exec" {
    command     = <<-EOT
      set -e
      echo "Waiting for Cloud Run service to be ready..."
      sleep 5

      echo "Updating traffic to latest revision..."
      gcloud run services update-traffic ${local.backend_app_name} \
        --region=${var.region} \
        --project=${module.project.project_id} \
        --to-latest \
        --quiet || true

      echo "Traffic updated successfully"
    EOT
    interpreter = ["bash", "-c"]
  }

  depends_on = [module.cloud_run_backend]
}
