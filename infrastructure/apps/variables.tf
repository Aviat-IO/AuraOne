variable "env" {
  description = "The environment to deploy to"
  type        = string
}

variable "project_id" {
  description = "The project ID to deploy to"
  type        = string
}

variable "region" {
  description = "The region to deploy to"
  type        = string
}

variable "labels" {
  description = "The labels to attach to all resources"
  type        = map(string)
}

variable "billing_account" {
  description = "The billing account to use for the project"
  type        = string
}

variable "organization_id" {
  description = "The organization ID to deploy to"
  type        = string
}

variable "folder_id" {
  description = "The folder ID to deploy to"
  type        = string
}

variable "project_name" {
  description = "The project name"
  type        = string
}

variable "project_title" {
  description = "The project title"
  type        = string
}

variable "backend_dir" {
  description = "The backend directory path (optional, defaults to relative path)"
  type        = string
  default     = ""
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection on Cloud Run services"
  type        = bool
  default     = false
}
