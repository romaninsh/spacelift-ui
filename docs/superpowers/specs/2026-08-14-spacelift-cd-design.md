# Spacelift CD demo — design

**Date:** 2026-08-14
**Status:** approved, phase 1 in progress

## Purpose

A deliberately small pair of applications carried through a deliberately serious
continuous-delivery pipeline. The applications exist to make the pipeline visible: what
matters here is how a version is built, tagged, promoted between environments, and
reported back — not what the applications compute.

Two things must be true at the end. An artifact promoted from one environment to the next
must be provably the same artifact, byte for byte. And at any moment it must be possible
to ask what is actually running in each environment and get an answer from the platform
rather than from a file someone remembered to update.

## Scope

In scope: two Cloud Run services, reusable OpenTofu modules, three Spacelift stacks,
GitHub Actions for build and release, a CLI that answers questions about the system, and
a Vantage dashboard built on that CLI.

Out of scope for now, listed so the design leaves room for them: real environment
variables held in Secret Manager, feature flags moved from tofu into Spacelift stack
variables, mechanical enforcement of the promotion ladder, the `augment:` pass on the
dashboard, and a fifth environment.

## Components

Three components, each independently versioned and independently taggable.

| Component  | What it is                          | Deploys to                    |
|------------|-------------------------------------|-------------------------------|
| `base`     | Shared GCP foundation               | Nothing — it *is* the foundation |
| `api`      | Rust service                        | Cloud Run, one service per env |
| `frontend` | Static JS served over HTTP          | Cloud Run, one service per env |

`base` is versioned and tagged like the others so its changes get release markers and a
changelog, even though it has no image and no per-environment version.

## Environments

`dev`, `uat`, `stg`, `prd`, in that order. A fifth will be added later. All four live in
the same GCP project — `inlaid-agility-461020-e4`, region `europe-west2` — because this is
a test system. Isolation between environments is by service name and service account, not
by project.

Cloud Run services are named `<component>-<env>`: `api-dev`, `frontend-prd`, and so on.

## Versioning and tagging

Git tags are component-prefixed and carry a bare semantic version with no `v`:

```
api-1.2.3
frontend-0.4.1
base-0.1.0
```

Pushing such a tag builds only that component. The resulting image is pushed to Artifact
Registry at
`europe-west2-docker.pkg.dev/inlaid-agility-461020-e4/apps/<component>` under two tags —
the semantic version and `sha-<short>` — and its digest is captured.

## Promotion

### What gets promoted

The **digest**, not the tag. A tag is a mutable pointer that is re-resolved at apply time,
so promoting a tag allows production to receive a different artifact than the one staging
tested. Promoting a digest makes "the same bits ran in every environment" a property the
system can demonstrate rather than a convention people follow. The semantic version rides
alongside the digest for human readability and for the dashboard's newer/older colouring;
it is never what the deployment resolves.

### Where the promoted digest lives

Each application stack owns one file, sitting next to the stack root that consumes it:

```hcl
# infra/stacks/api/deploy.auto.tfvars
deployments = {
  dev = {
    version  = "api-1.2.3"
    digest   = "sha256:abc…"
    features = { color = "green" }
  }
  uat = { version = "api-1.2.2", digest = "sha256:def…", features = { color = "blue" } }
  stg = { … }
  prd = { … }
}
```

Everything that varies per environment lives in this one map: the artifact, its human
version, and the feature flags. The stack root does `for_each = var.deployments` into
`module "app"`, so a change to a single entry produces a diff confined to a single Cloud
Run service.

There is deliberately no top-level `envs/` directory. Desired state lives in tofu next to
the stack that applies it; actual state is read from the platform. Nothing needs to sit
between them.

### The flow

Pushing `api-1.2.3` builds, pushes, captures the digest, and commits that digest into the
`dev` entry of `infra/stacks/api/deploy.auto.tfvars`. Dev is therefore always the newest
build, with no human in the loop.

Every promotion above dev is explicit: copy the exact digest from the source environment's
entry into the target environment's entry and open a pull request. Spacelift plans on the
pull request and applies on merge. Rollback is reverting that commit.

## Spacelift topology

Three stacks.

| Stack      | Root                    | Owns                                        |
|------------|-------------------------|---------------------------------------------|
| `base`     | `infra/stacks/base`     | APIs, Artifact Registry, WIF, service accounts, per-env base resources |
| `api`      | `infra/stacks/api`      | `api-{dev,uat,stg,prd}`                     |
| `frontend` | `infra/stacks/frontend` | `frontend-{dev,uat,stg,prd}`                |

Each stack's `project_root` scopes what triggers it, so editing
`infra/stacks/api/deploy.auto.tfvars` triggers the `api` stack and nothing else.

The consequence of one stack per *application* rather than per *environment* is that a
promotion to `stg` produces a plan whose state also contains the `prd` resources. The
`for_each` keeps the diff confined to the changed service, but the stack boundary is no
longer the guardrail. So the guardrail is explicit: **a Spacelift approval policy requiring
human approval for any plan whose diff touches a `prd` resource.** Drift detection runs on
all three stacks.

Infrastructure code is global to its stack — the stack tracks `main`, and every
environment it manages gets the same module code. Per-environment infrastructure pinning
is not possible here, because OpenTofu module `source` cannot be interpolated; four
per-environment refs would mean four hardcoded module blocks and the tfvars file would stop
being the promotion surface. If per-environment infrastructure pinning becomes necessary,
the path is to split into stack-per-environment, where each stack can track its own ref.

`base-X.Y.Z` tags are therefore release markers and changelog anchors, not per-environment
pins.

## Reusable modules

`infra/base` — enabled APIs, the Artifact Registry repository, the Workload Identity
Federation pool and provider that lets GitHub Actions push images, the per-environment
runtime service accounts, and later the Secret Manager secrets. Exports the shared
per-environment configuration (region, project, registry URL, service account emails) as
outputs.

`infra/app` — one Cloud Run service and its IAM, parameterised by component, environment,
image digest, feature flags, and later its secret bindings. Instantiated four times per
application stack.

Application stacks read `base`'s outputs through `terraform_remote_state` against the
shared GCS backend, so resolution is identical in Spacelift and on a laptop. The state
bucket and the initial API enablement are created once by a documented bootstrap script,
since they are the chicken-and-egg that no stack can create for itself.

Spacelift authenticates to GCP through its native workload-identity integration rather
than a long-lived service account key.

## The applications

Both applications follow the same rule, which the promotion model depends on: **identity is
baked at build time, configuration is read at runtime.** One image must run unchanged in
every environment, so it cannot learn its version from the environment, and it cannot learn
its environment from the build.

### `api`

Rust, axum. `/healthz` returns `ok`. `/version` returns:

```json
{ "version": "0.1.0", "color": "green" }
```

`version` is `CARGO_PKG_VERSION`, compiled in. `color` is the runtime feature flag, read
from `COLOR` and falling back to `gray` when unset or empty — so an unconfigured service is
visibly unconfigured rather than plausibly green. `SERVICE_HOST` (default `127.0.0.1`) and
`SERVICE_PORT` (default `8080`) control binding; Cloud Run needs `SERVICE_HOST=0.0.0.0`.

CORS is permissive, because the frontend calls the api from a different origin.

### `frontend`

Vite, React, TypeScript, Tailwind. It polls the api's `/version` once a second and spawns
bubbles in the returned colour at a runtime-configured rate. This makes a green/blue
switch-over directly visible: as Cloud Run shifts traffic between revisions, the bubble
stream changes colour mid-flight, and the proportion of each colour is the traffic split.
When the api is unreachable the bubbles go grey, so a broken backend is visible rather than
silent.

Its own version is baked at build time through Vite's `define`, taken from `package.json`
or overridden by `APP_VERSION` in CI, and shown in the bottom-left corner.

Runtime configuration cannot use Vite's env vars, which are inlined at build time and would
tie an image to one environment. It comes instead from `public/config.js`, loaded before the
bundle and read via `window.__CONFIG__`:

```js
window.__CONFIG__ = { apiUrl: 'http://127.0.0.1:8080', spawnSpeed: 2 }
```

The container entrypoint regenerates that file from environment variables at startup. One
artifact, per-environment configuration, and `spawnSpeed` is where the frontend feature flag
lands.

## `appctl`

A Rust CLI. Every subcommand prints JSON to stdout, which is what allows Vantage to treat
it as a `cmd` datasource — a locked binary whose output becomes table rows.

| Command             | Answers                                                    |
|---------------------|------------------------------------------------------------|
| `apps list`         | What components exist — from `apps.yaml`                    |
| `envs list`         | What environments exist, and their order — from `apps.yaml` |
| `deployments list`  | What is running where — via `gcloud run services describe`  |
| `prs list`          | Open pull requests, split into draft and in-review — via `gh pr list` |
| `promote`           | Copy a digest from one environment's entry to another's, open a PR |
| `features list`     | Current feature-flag values per environment (later phase)   |

`deployments list` computes a `drift` field itself — `current`, `behind`, or `stale` — by
comparing each environment's version against the newest for that component. Doing the
comparison in the CLI keeps semantic-version logic out of the dashboard, which then only
maps a value to a colour.

Subcommands that need GCP or GitHub ship stubbed first. The stub for `deployments list`
sleeps 0.8–1.5 seconds before answering, so the dashboard is built against realistic
latency rather than against an instant local file.

## `apps.yaml`

Pure inventory — which components exist, which environments exist, where each component's
code lives, and what its Cloud Run services are called. It carries **no versions at all**,
because desired version lives in tofu and actual version is read from the platform. That
absence is what makes the removal of a separate `envs/` directory lossless rather than a
gap.

## Vantage dashboard

Lives in `admin-2`, which is already scaffolded and connected over MCP.

One `cmd` datasource locked to the `appctl` binary. Four tables — `apps`, `environments`,
`deployments`, `pull_requests` — each fetching rows by running a subcommand and parsing its
JSON. A dashboard page carrying stat tiles for pull requests in draft and in review
alongside the deployments grid coloured by `drift`, plus a page per table.

The `augment:` block is not used. The table schema states it is consulted only by
`live_folder` faker families and ignored elsewhere, so it would be a no-op on a `cmd`
table. Per-row lazy hydration is deferred to a later pass.

Every change is verified with `list_logs` and `run_data_script` rather than by asking the
user.

## Repository layout

```
apps.yaml                           inventory: components and environments
api/                                Rust axum service
frontend/                           static JS
cli/                                appctl
infra/base/                         reusable module: GCP foundation
infra/app/                          reusable module: one Cloud Run service
infra/stacks/base/                  Spacelift stack root
infra/stacks/api/                   Spacelift stack root + deploy.auto.tfvars
infra/stacks/frontend/              Spacelift stack root + deploy.auto.tfvars
.github/workflows/                  ci, release
admin-2/                            Vantage dashboard
docs/superpowers/specs/             this document
compose.yaml, Makefile              local orchestration
```

## Local development

`cargo run` for the api and a static server for the frontend is the fast loop, wrapped in a
`Makefile`. `compose.yaml` and both Dockerfiles exist for parity with what CI builds.
Docker runs under colima, which is already installed and running; the compose plugin is
not currently installed, so the compose path requires `brew install docker-compose` first.

## Testing

The api has tests over `/healthz`, `/version`, and the grey fallback. The frontend has none
by choice — it is a demonstration surface, and its correctness is visible on screen. CI runs
`cargo fmt --check`, `cargo clippy -D warnings`, `cargo test`, `tsc -b`, `oxlint`, and
`tofu fmt -check` plus `tofu validate` on every module and stack root. A smoke step builds
both images and confirms each answers `/healthz`.

A `Makefile` at the root drives all of it: `install`, `build`, `test`, `lint`, `fmt`,
`clean`, `api`, `frontend`, `dev`.

## Error handling

The api answers `/version` even when degraded, because the dashboard's job is to report
reality. The frontend shows grey when the api is unreachable. `appctl` exits non-zero with
its message on stderr when an underlying tool fails, which is what surfaces the real error
in Vantage's logs rather than an empty table. Tofu applies that touch `prd` stop for human
approval.

## Phasing

**Phase 1** — the two applications running locally, then `apps.yaml`, the two modules, the
three stack roots, and the GitHub Actions. Tofu is written and validated but not applied.

**Phase 2** — apply the infrastructure for real, replace the stubs in `appctl` with real
`gcloud` and `gh` calls, and build the dashboard against them.

**Phase 3** — Secret Manager environment variables, feature flags moved into Spacelift
stack variables, mechanical enforcement of the promotion ladder, the `augment:` pass, and
the fifth environment.

## Step sequence

Each step stops for review before the next begins.

1. This document
2. `api`
3. `frontend`
4. `Makefile`, `compose.yaml`, Dockerfiles, verified under colima
5. `apps.yaml`
6. `infra/base` and `infra/app`
7. `infra/stacks/{base,api,frontend}`
8. GitHub Actions
9. `appctl`
10. Vantage dashboard
