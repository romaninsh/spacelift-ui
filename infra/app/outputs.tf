output "url" {
  description = "Service URL, empty when nothing is deployed here."
  value       = try(one(values(google_cloud_run_v2_service.this)).uri, "")
}

output "version" {
  description = "Deployed version, empty when nothing is deployed here."
  value       = try(local.deployment.version, "")
}
