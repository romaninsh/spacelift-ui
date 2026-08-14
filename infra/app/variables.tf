# This root is shared by every service stack. Which service it deploys comes
# from the stack, as TF_VAR_component.
variable "component" {
  description = "Service component key, e.g. api. Selects deployments/<component>.yaml."
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
  description = "Image path without a digest, e.g. europe-west2-docker.pkg.dev/p/api/api. Supplied by the base stack."
  type        = string
}

variable "api_urls" {
  description = "Api URL per environment, supplied by the api stack. Empty for the api itself."
  type        = map(string)
  default     = {}
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
