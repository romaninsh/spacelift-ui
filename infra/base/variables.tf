variable "project" {
  description = "GCP project hosting everything."
  type        = string
}

variable "region" {
  description = "Region for the registry and services."
  type        = string
}

variable "environments" {
  description = "Environment keys, in promotion order."
  type        = list(string)
}

variable "services" {
  description = "Service component keys, one Spacelift stack each."
  type        = list(string)
}

variable "teams" {
  description = "Owning team per component key, including base. Becomes a team: label on each stack."
  type        = map(string)
}

variable "ci_api_key_id" {
  description = "Spacelift API key GitHub Actions uses. Created by hand; empty leaves CI unbound."
  type        = string
  default     = ""
}

variable "github_repository" {
  description = "owner/name of the repository allowed to push images."
  type        = string
}
