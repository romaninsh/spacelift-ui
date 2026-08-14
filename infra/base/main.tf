locals {
  apis = [
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "sts.googleapis.com",
  ]

  runtime_accounts = {
    for pair in setproduct(var.services, var.environments) :
    "${pair[0]}-${pair[1]}" => { component = pair[0], environment = pair[1] }
  }
}

resource "google_project_service" "this" {
  for_each = toset(local.apis)

  project = var.project
  service = each.value

  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "apps" {
  project       = var.project
  location      = var.region
  repository_id = var.repository
  format        = "DOCKER"
  description   = "Application images promoted by digest across environments."

  depends_on = [google_project_service.this]
}

# One runtime identity per service per environment, so a compromised service in
# one environment cannot act as another.
resource "google_service_account" "runtime" {
  for_each = local.runtime_accounts

  project      = var.project
  account_id   = "run-${each.key}"
  display_name = "Cloud Run ${each.value.component} (${each.value.environment})"

  depends_on = [google_project_service.this]
}

# GitHub Actions pushes images by exchanging its OIDC token, so there is no
# long-lived service account key anywhere.
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions"

  depends_on = [google_project_service.this]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub Actions"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # Without this, any GitHub repository in the world could mint tokens.
  attribute_condition = "assertion.repository == '${var.github_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "ci" {
  project      = var.project
  account_id   = "github-actions"
  display_name = "GitHub Actions image publisher"

  depends_on = [google_project_service.this]
}

resource "google_service_account_iam_member" "ci_workload_identity" {
  service_account_id = google_service_account.ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}

resource "google_artifact_registry_repository_iam_member" "ci_writer" {
  project    = var.project
  location   = google_artifact_registry_repository.apps.location
  repository = google_artifact_registry_repository.apps.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.ci.email}"
}
