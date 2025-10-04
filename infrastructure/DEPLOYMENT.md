# Aura One Infrastructure Deployment Guide

This guide walks through deploying the Aura One GCP infrastructure using Terragrunt and Cloud Foundation Fabric.

## Prerequisites

- Terragrunt installed: `brew install terragrunt`
- Terraform installed: `brew install tfenv && tfenv install 1.5.0`
- Google Cloud SDK: `brew install google-cloud-sdk`
- Authenticated with GCP: `gcloud auth application-default login`

## Project Overview

This infrastructure creates:
- **Dev Environment**: `aura-one-dev`
- **Staging Environment**: `aura-one-staging`

Each environment includes:
- GCP Project with folder-based organization
- Vertex AI (Gemini 2.0 Flash)
- Firestore Native mode database
- Cloud Run (for backend deployment)
- Cloud Build (for container builds)
- Cloud Logging & Monitoring

## Initial Setup

### 1. Verify Backend Project

The Terraform state is stored in the `aviat-terraform` project. Verify the GCS bucket exists:

```bash
gsutil ls gs://aviat-terraform-tfstate
```

If the bucket doesn't exist, create it:

```bash
gcloud storage buckets create gs://aviat-terraform-tfstate \
  --project=aviat-terraform \
  --location=us \
  --uniform-bucket-level-access
```

### 2. Enable Required APIs in Backend Project

```bash
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  storage.googleapis.com \
  --project=aviat-terraform
```

## Deployment Steps

### Deploy Dev Environment

```bash
# Navigate to dev environment
cd infrastructure/terragrunt/dev

# Initialize Terragrunt
terragrunt init

# Review the plan
terragrunt plan

# Apply the configuration
terragrunt apply
```

This will:
1. Create the `aura-one-dev` GCP project
2. Enable all required APIs
3. Create Firestore database in Native mode with dev settings:
   - Delete protection: DISABLED (for easier cleanup)
   - Point-in-time recovery: DISABLED (cost optimization)

### Deploy Staging Environment

```bash
# Navigate to staging environment
cd infrastructure/terragrunt/staging

# Initialize Terragrunt
terragrunt init

# Review the plan
terragrunt plan

# Apply the configuration
terragrunt apply
```

This will:
1. Create the `aura-one-staging` GCP project
2. Enable all required APIs
3. Create Firestore database in Native mode with production settings:
   - Delete protection: ENABLED (prevent accidental deletion)
   - Point-in-time recovery: ENABLED (disaster recovery)

## Post-Deployment Configuration

### 1. Verify Project Creation

```bash
# List projects
gcloud projects list --filter="name:aura-one"

# Should show:
# - aura-one-dev
# - aura-one-staging
```

### 2. Set Up Application Default Credentials

For local backend development:

```bash
# Authenticate as yourself
gcloud auth application-default login

# Set the project
gcloud config set project aura-one-dev
```

For Cloud Run deployment, the backend will use Application Default Credentials automatically.

### 3. Verify Firestore Database

```bash
# Check Firestore database (dev)
gcloud firestore databases list --project=aura-one-dev

# Check Firestore database (staging)
gcloud firestore databases list --project=aura-one-staging
```

### 4. Get Project Information

```bash
# Get dev project number (needed for IAM)
gcloud projects describe aura-one-dev --format="value(projectNumber)"

# Get staging project number
gcloud projects describe aura-one-staging --format="value(projectNumber)"
```

## Backend Deployment

Once the infrastructure is deployed, you can deploy the Bun backend:

### 1. Update Backend Environment Variables

Create `backend/.env` for local development:

```bash
# For dev environment
GCP_PROJECT_ID=aura-one-dev
GCP_LOCATION=us-central1
NODE_ENV=development
PORT=5566
```

### 2. Build and Deploy to Cloud Run

```bash
# Authenticate Docker with GCP
gcloud auth configure-docker

# Build the container
cd backend
gcloud builds submit --tag gcr.io/aura-one-dev/aura-one-backend

# Deploy to Cloud Run
gcloud run deploy aura-one-backend \
  --image gcr.io/aura-one-dev/aura-one-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars GCP_PROJECT_ID=aura-one-dev,GCP_LOCATION=us-central1 \
  --project aura-one-dev
```

### 3. Update Mobile App Backend URL

After Cloud Run deployment, update the mobile app configuration:

```dart
// In mobile-app/lib/services/ai/managed_cloud_gemini_adapter.dart
static const String _defaultBackendUrl = 'https://aura-one-backend-<hash>-uc.a.run.app';
```

Replace `<hash>` with the actual Cloud Run URL from the deployment output.

## Firestore Security Rules

After deployment, configure Firestore security rules:

```bash
# Navigate to project root
cd infrastructure

# Deploy security rules (create this file first)
gcloud firestore indexes create firestore.rules --project=aura-one-dev
```

Create `infrastructure/firestore.rules`:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Usage collection - devices can read/write their own usage
    match /usage/{deviceId} {
      allow read, write: if request.auth == null; // Anonymous access for free tier
    }

    // Accounts collection - authenticated users only
    match /accounts/{accountId} {
      allow read, write: if request.auth != null && request.auth.uid == accountId;
    }
  }
}
```

## Infrastructure Updates

To update existing infrastructure:

```bash
# Pull latest Terraform modules
cd infrastructure/terragrunt/dev
terragrunt get -update

# Review changes
terragrunt plan

# Apply changes
terragrunt apply
```

## Troubleshooting

### "Project already exists" Error

If you get an error about the project already existing:

```bash
# Import existing project into Terraform state
cd infrastructure/terragrunt/dev
terragrunt import module.project.google_project.project aura-one-dev
```

### API Not Enabled Error

```bash
# Manually enable an API
gcloud services enable <api-name> --project=aura-one-dev
```

### Firestore Database Already Exists

Firestore databases cannot be deleted. If you need to start fresh, you'll need to create a new project.

## Cost Optimization

### Dev Environment
- Delete protection disabled for easier cleanup
- Point-in-time recovery disabled (saves ~$0.18/GB/month)
- Can delete project when not in use

### Staging Environment
- Delete protection enabled (production-like)
- Point-in-time recovery enabled (disaster recovery)
- Keep running for testing

## Cleanup

To destroy an environment:

```bash
cd infrastructure/terragrunt/dev
terragrunt destroy

# Manually delete the project (Firestore databases prevent automatic deletion)
gcloud projects delete aura-one-dev
```

**Note**: Firestore databases cannot be deleted via Terraform. You must delete the entire project to remove the Firestore database.

## Next Steps

1. ✅ Deploy infrastructure to dev
2. ✅ Deploy infrastructure to staging
3. Deploy backend to Cloud Run
4. Configure Firestore security rules
5. Update mobile app with Cloud Run URL
6. Test end-to-end flow
7. Monitor logs and metrics

## Support

For issues:
- Check GCP Console for detailed error messages
- Review Terraform/Terragrunt logs
- Verify IAM permissions
- Check service quotas
