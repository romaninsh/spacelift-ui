locals {
  # The promotion surface. One entry per environment this component is deployed
  # to; an environment absent from the file has no service.
  deployments = yamldecode(file("${path.module}/deployments/${var.component}.yaml"))

  # Feature flags and their defaults are declared once, in the inventory. An
  # environment overrides one by naming it under its own features block.
  inventory = yamldecode(file("${path.module}/../../apps.yaml"))
  spec      = one([for component in local.inventory.components : component if component.key == var.component])

  feature_defaults = {
    for feature in try(local.spec.features, []) :
    feature.variable => tostring(feature.default)
  }

  # Platform wiring this root owns, so a deployments file cannot forget it. Both
  # applications bind loopback by default, which inside Cloud Run means no
  # traffic ever arrives and the health check fails.
  wiring = {
    SERVICE_HOST = "0.0.0.0"
    SERVICE_PORT = tostring(var.port)
  }
}

resource "google_cloud_run_v2_service" "this" {
  for_each = local.deployments

  name                = "${var.component}-${each.key}"
  project             = var.project
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_ALL"
  deletion_protection = false

  labels = {
    component   = var.component
    environment = each.key
    version     = replace(each.value.version, ".", "-")
  }

  template {
    # Naming matches the accounts the base stack creates, so the two stay in
    # step without passing a map between stacks.
    service_account = "run-${var.component}-${each.key}@${var.project}.iam.gserviceaccount.com"

    scaling {
      min_instance_count = 0
      max_instance_count = var.max_instances
    }

    containers {
      image = "${var.image}@${each.value.digest}"

      ports {
        container_port = var.port
      }

      dynamic "env" {
        for_each = merge(
          local.wiring,
          { APP_ENV = each.key },
          local.feature_defaults,
          try(lookup(each.value, "features", {}), {}),
          # Only the frontend receives this; the api stack supplies no urls.
          try({ APP_API_URL = var.api_urls[each.key] }, {}),
        )

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

  lifecycle {
    precondition {
      # Promoting a tag would let the resolved artifact drift between
      # environments. Only a digest promotes the thing that was tested.
      condition     = can(regex("^sha256:[0-9a-f]{64}$", each.value.digest))
      error_message = "${var.component}/${each.key}: digest must be sha256:<64 hex>, got ${each.value.digest}."
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  for_each = google_cloud_run_v2_service.this

  project  = each.value.project
  location = each.value.location
  name     = each.value.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
