# Terragrunt Template

This is a template repository showing how to structure Terragrunt according to best practices. This code should be copied to a new project as a top-level folder.

## Installation

- Terragrunt: `brew install terragrunt`
- Terraform: `brew install tfenv`. Then `tfenv install [version]`

## Configuration

- Update the `root.hcl` file with your project specifics
- Within each environment you'd like to deploy, run `cp terraform.tfvars.example terraform.tfvars` and update the values

## Setup

You must create a backend project to host the Terraform state (in a GCS bucket)

```bash
BACKEND_PROJECT=aviat-terraform
gcloud projects create $BACKEND_PROJECT
```

And then enable the following APIs

```bash
gcloud services enable \
  cloudbuild.googleapis.com \
  cloudresourcemanager.googleapis.com \
  firebase.googleapis.com \
  iam.googleapis.com \
  identitytoolkit.googleapis.com \
  orgpolicy.googleapis.com \
  storage.googleapis.com \
  --project=$BACKEND_PROJECT
```

## Deploy

- `cd` in the environment you'd like to deploy
- Run `terragrunt init`
- Run `terragrunt apply`
