module "firestore" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/firestore"
  project_id = module.project.project_id

  database = {
    name                        = "(default)"
    location_id                 = var.region
    type                        = "FIRESTORE_NATIVE"
    delete_protection_state     = var.env == "prod" || var.env == "staging" ? "DELETE_PROTECTION_ENABLED" : "DELETE_PROTECTION_DISABLED"
    point_in_time_recovery_enablement = var.env == "prod" || var.env == "staging" ? "POINT_IN_TIME_RECOVERY_ENABLED" : "POINT_IN_TIME_RECOVERY_DISABLED"
  }

  # Firestore indexes will be created as needed by the application
}
