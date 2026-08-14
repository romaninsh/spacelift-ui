package spacelift

# A run whose plan touches a prd resource waits for a human. Everything below
# production applies on merge, unattended.

touches_production {
    contains(input.run.changes[_].entity.address, "\"prd\"")
}

approve {
    not touches_production
}

approve {
    touches_production
    count(input.reviews.current.approvals) > 0
}

reject {
    count(input.reviews.current.rejections) > 0
}
