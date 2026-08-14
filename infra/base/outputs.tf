output "registry" {
  description = "Base path images are published under."
  value       = local.registry
}

output "ci_service_account" {
  description = "Identity GitHub Actions impersonates to push images."
  value       = google_service_account.ci.email
}

output "workload_identity_provider" {
  description = "Provider resource name for google-github-actions/auth."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "stack_ids" {
  description = "Spacelift stack per service."
  value       = { for key, stack in spacelift_stack.app : key => stack.id }
}
