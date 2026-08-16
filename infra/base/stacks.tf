locals {
  repository = split("/", var.github_repository)[1]

  # One stack per service per environment. Production changes cannot ride along
  # with a dev release, drift in one environment cannot block another, and each
  # environment keeps its own state and its own lock.
  app_stacks = {
    for pair in setproduct(var.services, var.environments) :
    "${pair[0]}-${pair[1]}" => { component = pair[0], environment = pair[1] }
  }

  production = "prd"
}

# Spacelift managing Spacelift. This stack is created once out of band; it
# defines every other stack. They all share one project root and differ by
# TF_VAR_component and TF_VAR_environment.
resource "spacelift_stack" "app" {
  for_each = local.app_stacks

  name        = each.key
  description = "${each.value.component} in ${each.value.environment}."

  repository   = local.repository
  branch       = "main"
  project_root = "infra/app"

  terraform_workflow_tool = "OPEN_TOFU"
  manage_state            = true

  # Production waits for a human instead of needing a policy to say so.
  autodeploy = each.value.environment != local.production

  labels = [
    "component:${each.value.component}",
    "environment:${each.value.environment}",
    "team:${var.teams[each.value.component]}",
  ]
}

resource "spacelift_environment_variable" "component" {
  for_each = local.app_stacks

  stack_id   = spacelift_stack.app[each.key].id
  name       = "TF_VAR_component"
  value      = each.value.component
  write_only = false
}

resource "spacelift_environment_variable" "environment" {
  for_each = local.app_stacks

  stack_id   = spacelift_stack.app[each.key].id
  name       = "TF_VAR_environment"
  value      = each.value.environment
  write_only = false
}

resource "spacelift_environment_variable" "project" {
  for_each = local.app_stacks

  stack_id   = spacelift_stack.app[each.key].id
  name       = "TF_VAR_project"
  value      = var.project
  write_only = false
}

resource "spacelift_environment_variable" "region" {
  for_each = local.app_stacks

  stack_id   = spacelift_stack.app[each.key].id
  name       = "TF_VAR_region"
  value      = var.region
  write_only = false
}

resource "spacelift_environment_variable" "image" {
  for_each = local.app_stacks

  stack_id   = spacelift_stack.app[each.key].id
  name       = "TF_VAR_image"
  value      = local.images[each.value.component]
  write_only = false
}

# Cloud Run URLs carry a generated hash, so a frontend cannot derive the address
# of the api beside it — the api stack for the same environment hands it over.
resource "spacelift_stack_dependency" "frontend_on_api" {
  for_each = toset(var.environments)

  stack_id            = spacelift_stack.app["frontend-${each.value}"].id
  depends_on_stack_id = spacelift_stack.app["api-${each.value}"].id
}

resource "spacelift_stack_dependency_reference" "api_url" {
  for_each = spacelift_stack_dependency.frontend_on_api

  stack_dependency_id = each.value.id
  input_name          = "TF_VAR_api_url"
  output_name         = "url"
}

# Each stack gets its own generated GCP identity rather than a shared key.
resource "spacelift_stack_gcp_service_account" "app" {
  for_each = local.app_stacks

  stack_id     = spacelift_stack.app[each.key].id
  token_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
}

resource "google_project_iam_member" "app_run_admin" {
  for_each = spacelift_stack_gcp_service_account.app

  project = var.project
  role    = "roles/run.admin"
  member  = "serviceAccount:${each.value.service_account_email}"
}

# Deploying a service that runs as a service account requires acting as it.
resource "google_project_iam_member" "app_service_account_user" {
  for_each = spacelift_stack_gcp_service_account.app

  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${each.value.service_account_email}"
}

# Cloud Run refuses to create a service unless the identity deploying it can
# itself read the image, so run.admin alone is not enough.
resource "google_artifact_registry_repository_iam_member" "stack_reader" {
  for_each = local.app_stacks

  project    = var.project
  location   = var.region
  repository = google_artifact_registry_repository.app[each.value.component].name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${spacelift_stack_gcp_service_account.app[each.key].service_account_email}"
}

resource "spacelift_drift_detection" "app" {
  for_each = local.app_stacks

  stack_id  = spacelift_stack.app[each.key].id
  reconcile = false
  schedule  = ["0 6 * * *"]
}
