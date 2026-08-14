output "urls" {
  description = "Service URL per environment. The frontend stack consumes the api stack's copy."
  value       = { for env, service in google_cloud_run_v2_service.this : env => service.uri }
}

output "versions" {
  description = "Deployed version per environment."
  value       = { for env, deployment in local.deployments : env => deployment.version }
}
