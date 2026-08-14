variable "component" {
  description = "Service component key, e.g. api. Set by the base stack."
  type        = string
}

variable "project" {
  description = "GCP project hosting the services."
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

variable "api_urls" {
  description = "Api URL per environment, from the api stack. Empty for the api itself."
  type        = map(string)
  default     = {}
}

# What is deployed where. One JSON document per environment — {version, digest,
# features} — held as a stack variable rather than in the repository, so a
# release or a promotion is an API call and never a commit. Empty means the
# environment has no service. Deliberately not managed by the base stack, which
# would otherwise revert every release on its next apply.
variable "deploy_dev" {
  type    = string
  default = ""
}

variable "deploy_uat" {
  type    = string
  default = ""
}

variable "deploy_stg" {
  type    = string
  default = ""
}

variable "deploy_prd" {
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
