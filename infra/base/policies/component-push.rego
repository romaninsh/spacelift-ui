package spacelift

# Both service stacks share infra/app as their project root, so the default
# policy would run each of them whenever either component's deployments file
# changed. A stack cares about the shared code and about its own file only.
#
# The component is read from the stack's own "component:<name>" label, so this
# policy never needs editing when a service is added.

component := trim_prefix(label, "component:") {
    label := input.stack.labels[_]
    startswith(label, "component:")
}

own_deployment_file := sprintf("infra/app/deployments/%s.yaml", [component])

# A change to any other component's deployments file is not ours.
relevant(path) {
    startswith(path, "infra/app/")
    not startswith(path, "infra/app/deployments/")
}

relevant(path) {
    path == own_deployment_file
}

affected {
    relevant(input.push.affected_files[_])
}

affected_pr {
    relevant(input.pull_request.diff[_])
}

track {
    affected
    input.push.branch == input.stack.branch
}

propose { affected }

propose { affected_pr }

ignore {
    not affected
    not affected_pr
}

ignore { input.push.tag != "" }
