output "project" {
  description = "GCP project."
  value       = var.project
}

output "region" {
  description = "Region for services and the registry."
  value       = var.region
}

output "registry" {
  description = "Base path images are published under."
  value       = "${var.region}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.apps.repository_id}"
}

output "runtime_service_accounts" {
  description = "Runtime identity per <component>-<environment>."
  value       = { for key, account in google_service_account.runtime : key => account.email }
}

output "ci_service_account" {
  description = "Identity GitHub Actions impersonates to push images."
  value       = google_service_account.ci.email
}

output "workload_identity_provider" {
  description = "Provider resource name for google-github-actions/auth."
  value       = google_iam_workload_identity_pool_provider.github.name
}
