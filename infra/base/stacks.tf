locals {
  repository = split("/", var.github_repository)[1]
}

# Spacelift managing Spacelift. This stack is created once out of band; it
# defines every other stack. Both service stacks share one project root and
# differ only by TF_VAR_component.
resource "spacelift_stack" "app" {
  for_each = toset(var.services)

  name        = each.value
  description = "Cloud Run service ${each.value} across ${join(", ", var.environments)}."

  repository   = local.repository
  branch       = "main"
  project_root = "infra/app"

  terraform_workflow_tool = "OPEN_TOFU"
  manage_state            = true
  autodeploy              = true

  labels = ["component:${each.value}"]
}

resource "spacelift_environment_variable" "component" {
  for_each = spacelift_stack.app

  stack_id    = each.value.id
  name        = "TF_VAR_component"
  value       = each.key
  write_only  = false
  description = "Which service this stack deploys."
}

resource "spacelift_environment_variable" "project" {
  for_each = spacelift_stack.app

  stack_id   = each.value.id
  name       = "TF_VAR_project"
  value      = var.project
  write_only = false
}

resource "spacelift_environment_variable" "region" {
  for_each = spacelift_stack.app

  stack_id   = each.value.id
  name       = "TF_VAR_region"
  value      = var.region
  write_only = false
}

resource "spacelift_environment_variable" "image" {
  for_each = spacelift_stack.app

  stack_id   = each.value.id
  name       = "TF_VAR_image"
  value      = local.images[each.key]
  write_only = false
}

# Cloud Run URLs carry a generated hash, so the frontend cannot derive the
# address of the api in its own environment — the api stack has to hand it over.
resource "spacelift_stack_dependency" "frontend_on_api" {
  stack_id            = spacelift_stack.app["frontend"].id
  depends_on_stack_id = spacelift_stack.app["api"].id
}

resource "spacelift_stack_dependency_reference" "api_urls" {
  stack_dependency_id = spacelift_stack_dependency.frontend_on_api.id
  input_name          = "TF_VAR_api_urls"
  output_name         = "urls"
}

# Each stack gets its own generated GCP identity rather than a shared key.
resource "spacelift_stack_gcp_service_account" "app" {
  for_each = spacelift_stack.app

  stack_id     = each.value.id
  token_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
}

resource "google_project_iam_member" "app_run_admin" {
  for_each = spacelift_stack_gcp_service_account.app

  project = var.project
  role    = "roles/run.admin"
  member  = "serviceAccount:${each.value.service_account_email}"
}

# Cloud Run refuses to create a service unless the identity deploying it can
# itself read the image, so run.admin alone is not enough.
resource "google_artifact_registry_repository_iam_member" "stack_reader" {
  for_each = spacelift_stack_gcp_service_account.app

  project    = var.project
  location   = var.region
  repository = google_artifact_registry_repository.app[each.key].name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${each.value.service_account_email}"
}

# Deploying a service that runs as a service account requires acting as it.
resource "google_project_iam_member" "app_service_account_user" {
  for_each = spacelift_stack_gcp_service_account.app

  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${each.value.service_account_email}"
}

# One stack per service means the stack boundary no longer separates production
# from everything else, so the separation becomes an explicit policy.
resource "spacelift_policy" "production_approval" {
  name = "Production changes need approval"
  type = "APPROVAL"
  body = file("${path.module}/policies/production-approval.rego")
}

resource "spacelift_policy_attachment" "production_approval" {
  for_each = spacelift_stack.app

  policy_id = spacelift_policy.production_approval.id
  stack_id  = each.value.id
}

# Sharing a project root means the default push policy would run both service
# stacks whenever either component's deployments file changes.
resource "spacelift_policy" "component_push" {
  name = "Only run a stack for its own component"
  type = "GIT_PUSH"
  body = file("${path.module}/policies/component-push.rego")
}

resource "spacelift_policy_attachment" "component_push" {
  for_each = spacelift_stack.app

  policy_id = spacelift_policy.component_push.id
  stack_id  = each.value.id
}

resource "spacelift_drift_detection" "app" {
  for_each = spacelift_stack.app

  stack_id  = each.value.id
  reconcile = false
  schedule  = ["0 6 * * *"]
}
