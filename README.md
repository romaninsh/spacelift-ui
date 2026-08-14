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
registry. When builds become complex, this saves signifant amount of time, makes engineering teams
happy.

## Safety

You would want to enable peer reviews and with enforced version bumps you can also loop in validation
for PR titles, merge squishes - whichever your organisation prefers.

Once code is changed - it's considered source of truth and will be promoted or rolled back or
superseeded by next release.

## Permissions

Spacelift has stacks for all envs*apps combination. If your organisation has hundreds of apps,
and 4-5 envs, managing this all is diffcult, so we introduce simple rule - you can only
push app version if it's used in lower environmen and that enviromnent is healthy.

Both app versions and feature flag values are stored in spacelift.

## Terraform stacks

While I have included some basic stack, you can create logic around feature flags or add more
features in app deployment. This does not affect a basic principle of this example, start
with a simple concept, then grow it.

## appctl

This command is a wrapper designed for 2 things
 - retrieve things from APIs and output as json
 - execute version promotions safely.

Vantage UI supports a `cmd` backend, which is this app exactly. It will source your infrastructrue
data and visualise but also provide interractivity.

# End-to-end walk

Clone this repo, then create stacks in your own spacelift account, connect your GCP and deploy dev
stack. Edit apps.yml to configure your applications and environments.

Raise PR - make sure tests pass, bump version, merge. On merge artifact should be deployed if OIDC in
base is configured correctly.

This should also trigger `dev` stack deployment (for whicever app you changed version).

Open frontend URL (you can find in GCP cloud-run console), and you should see green bubbles raising
on the screen.

## Use Vantage UI

Download vantage-ui, open `admin` folder and make sure your spacectl is authenticated. UI should
work out of the box and you should be able to promote app versions and maybe even edit feature
flags.

When you deploy new `api` version, it should reflect on the frontend screen.
