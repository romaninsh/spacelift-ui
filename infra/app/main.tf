locals {
  name = "${var.component}-${var.environment}"

  # Platform wiring the module owns, so a stack root cannot forget it. Both
  # applications bind loopback by default, which inside Cloud Run means no
  # traffic ever arrives and the health check fails.
  wiring = {
    SERVICE_HOST = "0.0.0.0"
    SERVICE_PORT = tostring(var.port)
    APP_ENV      = var.environment
  }
}

resource "google_cloud_run_v2_service" "this" {
  name                = local.name
  project             = var.project
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  labels = {
    component   = var.component
    environment = var.environment
    version     = replace(var.version_label, ".", "-")
  }

  template {
    service_account = var.service_account_email

    scaling {
      min_instance_count = 0
      max_instance_count = var.max_instances
    }

    containers {
      image = var.image

      ports {
        container_port = var.port
      }

      dynamic "env" {
        for_each = merge(local.wiring, var.env_vars)

        content {
          name  = env.key
          value = env.value
        }
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      startup_probe {
        http_get {
          path = "/healthz"
        }

        failure_threshold = 6
        period_seconds    = 5
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = google_cloud_run_v2_service.this.project
  location = google_cloud_run_v2_service.this.location
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
