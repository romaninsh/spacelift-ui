variable "project" {
  description = "GCP project hosting the service."
  type        = string
}

variable "region" {
  description = "Cloud Run region."
  type        = string
}

variable "component" {
  description = "Component key from apps.yaml, e.g. api."
  type        = string
}

variable "environment" {
  description = "Environment key, e.g. stg."
  type        = string
}

variable "image" {
  description = "Digest-pinned image. Promoting a tag would let the resolved artifact drift between environments."
  type        = string

  validation {
    condition     = can(regex("@sha256:[0-9a-f]{64}$", var.image))
    error_message = "Image must be pinned by digest, e.g. europe-west2-docker.pkg.dev/p/apps/api@sha256:<64 hex>."
  }
}

variable "version_label" {
  description = "Human-readable version of the pinned digest, e.g. api-1.2.3. Recorded as a label only."
  type        = string
}

variable "service_account_email" {
  description = "Runtime identity for the service."
  type        = string
}

variable "port" {
  description = "Port the container listens on."
  type        = number
  default     = 8080
}

variable "env_vars" {
  description = "Runtime configuration, including APP_* feature flags."
  type        = map(string)
  default     = {}
}

variable "max_instances" {
  description = "Upper bound on concurrent instances."
  type        = number
  default     = 2
}
