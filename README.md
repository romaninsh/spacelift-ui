# spacelift-ui

This repository is a best-practice for your own enterprise-grade build, deploy and promote setup. Here
are some of the features built in:

 1. fast cached docker builds.
 2. sharp separation between ci and cd.
 3. github only has dev promotion access.
 4. spacelift promotion scripts for multi-env release coordination
 5. feature-flag support - both frontend and backend
 6. vantage-ui wrapper for the UI

## Resulting APP ui

tbc screenshot

Vantage UI (can be downloaded free from https://vantage-ui.com/) is a UI shell, which integrates at the
platform team access level. It works as a management console, but can also be used to deploy platform
API and expose custom promotion endpoints or integration with enterprise review and approval flow.

This platform backend is out of scope for this example repository.

## Applications, Monrepo and Local Development

There are multiple languages in the org, i included Rust and Typescript, both compile into containers
and are eventually launched into GCP cloud app. In larger ord you orchestrate with ArgoCD project sets
but the basic idea is similar.

If you want - you can deploy it - you'll need GCP and a free SpaceLift account.

I included Makefile - where you can just run `make dev` to build and run frontend/backend locally.
You would also want to run it in docker-compose: `make up`, just make sure ports are free.

## PRs

In your PRs you want to run test-suites. Some orgs want to build artifacts as part of PR run, here,
for simplicity I only do tests. Code is treated source of truth, once something is merged into
main, a `release` pipeline will take versions, build and push artifacts, then will tag commit.

## Caching

I have included docker caching, both dependency caches and i'm also restoring caches from artifact
registry. When builds become complex, this saves signifant amount of time.
