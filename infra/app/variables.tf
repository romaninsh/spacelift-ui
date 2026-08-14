variable "component" {
  description = "Service component key, e.g. api. Set by the base stack."
  type        = string
}

variable "environment" {
  description = "Environment this stack owns, e.g. stg. Set by the base stack."
  type        = string
}

variable "project" {
  description = "GCP project hosting the service."
  type        = string
}

variable "region" {
  description = "Cloud Run region."
  type        = string
}

variable "image" {
  description = "Image path without a digest. Set by the base stack."
  type        = string
}

variable "api_url" {
  description = "Api URL in this environment, from the matching api stack. Empty for the api itself."
  type        = string
  default     = ""
}

# What this environment runs: {version, digest, features} as JSON, held as a
# stack variable rather than in the repository, so a release or a promotion is
# an API call and never a commit. Empty means nothing is deployed here.
variable "deploy" {
  type    = string
  default = ""
}

variable "port" {
  description = "Port the container listens on."
  type        = number
  default     = 8080
}

variable "max_instances" {
  description = "Upper bound on concurrent instances."
  type        = number
  default     = 2
}
