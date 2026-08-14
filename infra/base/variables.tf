variable "project" {
  description = "GCP project hosting everything."
  type        = string
}

variable "region" {
  description = "Region for the registry and services."
  type        = string
}

variable "repository" {
  description = "Artifact Registry repository name."
  type        = string
  default     = "apps"
}

variable "environments" {
  description = "Environment keys, each getting its own runtime service account."
  type        = list(string)
}

variable "services" {
  description = "Service component keys from apps.yaml."
  type        = list(string)
}

variable "github_repository" {
  description = "owner/name of the repository allowed to push images."
  type        = string
}
