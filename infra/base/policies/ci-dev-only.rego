package spacelift

# Spacelift scopes STACK_ADD_CONFIG to a stack, not to a single variable, so
# the CI credential could technically pin any environment. This is what makes
# "CI publishes to dev only" enforceable rather than merely intended: a run it
# triggered may not change a resource belonging to another environment.

ci_triggered {
    contains(input.run.triggered_by, "github-actions")
}

deny[sprintf("CI may only deploy dev, but this run changes %s", [address])] {
    ci_triggered
    some i
    address := input.run.changes[i].entity.address
    contains(address, "google_cloud_run_v2_service")
    not contains(address, "\"dev\"")
}
