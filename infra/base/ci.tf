# CI publishes to dev and nothing else. The narrow role below is the first
# lock; the plan policy is the second, because STACK_ADD_CONFIG is scoped to a
# stack rather than to an individual variable — so permissions alone cannot
# stop a CI credential writing TF_VAR_deploy_prd.
resource "spacelift_role" "ci_dev_publisher" {
  name        = "CI dev publisher"
  description = "Set the dev deployment variable on a service stack and trigger a run."

  actions = [
    "SPACE_READ",
    "STACK_ADD_CONFIG",
    "RUN_TRIGGER",
  ]
}

# Spacelift refuses API key creation from non-human sessions, so the key is
# made once in the UI and named here. Binding it stays declarative.
resource "spacelift_role_attachment" "ci" {
  for_each = var.ci_api_key_id == "" ? {} : spacelift_stack.app

  role_id    = spacelift_role.ci_dev_publisher.id
  api_key_id = var.ci_api_key_id
  space_id   = "root"
  stack_id   = each.value.id
}

resource "spacelift_policy" "ci_dev_only" {
  name = "CI may only change dev"
  type = "PLAN"
  body = file("${path.module}/policies/ci-dev-only.rego")
}

resource "spacelift_policy_attachment" "ci_dev_only" {
  for_each = spacelift_stack.app

  policy_id = spacelift_policy.ci_dev_only.id
  stack_id  = each.value.id
}
