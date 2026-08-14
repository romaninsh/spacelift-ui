# CI publishes to dev and nothing else. With a stack per environment this is
# structural: the credential is bound to the two dev stacks, so uat, stg and
# prd are simply unreachable — no policy required to say so.
resource "spacelift_role" "ci_dev_publisher" {
  name        = "CI dev publisher"
  description = "Set the deployment variable on a dev stack and trigger a run."

  actions = [
    "SPACE_READ",
    "STACK_ADD_CONFIG",
    "RUN_TRIGGER",
  ]
}

# Spacelift refuses API key creation from non-human sessions, so the key is
# made once in the UI and named here. Binding it stays declarative.
resource "spacelift_role_attachment" "ci" {
  for_each = var.ci_api_key_id == "" ? toset([]) : toset(var.services)

  role_id    = spacelift_role.ci_dev_publisher.id
  api_key_id = var.ci_api_key_id
  space_id   = "root"
  stack_id   = spacelift_stack.app["${each.value}-dev"].id
}
