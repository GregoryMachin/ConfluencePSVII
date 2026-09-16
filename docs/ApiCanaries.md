# API contract canaries

**Added:** Phase 9 Task 60.

## Purpose

Detect a Confluence Cloud API contract change (a field disappearing, a route shape changing) before a user reports it, on a schedule tighter than the nightly full integration suite. This is deliberately separate from:

- `smoke_tests` (`.github/workflows/ci.yml`): runs on every first-party PR and push, gates merges and releases.
- `integration_tests.yml`: the full Cloud + Data Center regression suite, nightly.

Canaries are a health signal, not a regression suite: narrow scope, frequent for reads, less frequent (but still bounded) for the one write lifecycle they exercise.

## The two tiers

Both tiers reuse the existing `Tests/Integration/Configuration.Integration.Tests.ps1` Contexts rather than a separate file: they were already split exactly this way, so this task only added tags.

| Tier | Pester tag | Schedule | What it does |
|---|---|---|---|
| Read canary | `CanaryRead` | Every 4 hours | The `Integration Connectivity` and `Smoke Read Coverage` Contexts: authenticate, list spaces, query pages via CQL. No resource is created. |
| Write-lifecycle canary | `CanaryWrite` | Once daily (11:50 UTC, offset from the 05:00 UTC nightly full suite) | The `Smoke Write Coverage` Context: create a disposable space and page, update the page body, add and remove a label, add and remove an attachment, then delete the page and space. |

Both tiers are Cloud-only: Confluence Data Center is pinned, versioned software with no "surprise contract change" risk the way a continuously deployed Cloud API has, and is already covered by `integration_tests.yml`'s nightly Data Center track.

Both tiers, and manual runs via `workflow_dispatch`, live in `.github/workflows/api_canary.yml`.

## Required setup: a dedicated canary account

Both jobs authenticate as `ATLASSIAN_CANARY_USER` (repository variable) / `ATLASSIAN_CANARY_PAT` (repository secret) -- **a separate, least-privilege Confluence Cloud account and API token from the one `smoke_tests`/`integration_tests.yml` use (`ATLASSIAN_CLOUD_USER`/`ATLASSIAN_CLOUD_PAT`)**. This account needs permission to create and delete a space, since the write tier's disposable page lives in a disposable space it creates for itself.

Until that account and its variable/secret are provisioned, both canary jobs fail fast with an actionable "required environment variables are not set" error from `Invoke-Build -Task TestIntegration` rather than silently skipping or reporting a false green. Provisioning a real least-privilege Atlassian account and a GitHub Actions secret is a manual, live-credential step outside the scope of any automated change to this repository.

## Published results

Each job runs `Tools/Publish-ApiCanaryResult.ps1` after its Pester run (`if: always()`, so a failed or timed-out run still publishes what it has) and uploads the result as a workflow artifact alongside the raw NUnit XML:

- `Read-Canary-Results` / `api-canary-read-results.json`
- `Write-Canary-Results` / `api-canary-write-results.json`

Each JSON array entry is one operation's result: `SchemaVersion`, `Repository`, `Operation`, `DeploymentType`, `Status` (`Passed`/`Failed`/`Skipped`), `StartedAtUtc`, `CompletedAtUtc`, `DurationMilliseconds`, `Message`, `Metadata`. `Publish-ApiCanaryResult.ps1` builds these by calling `AtlassianPS.Standards`' own `ConvertTo-ApiCanaryResult`, imported via the version `Tools/build.requirements.psd1` pins.

`AtlassianPS.Standards` itself has not been published to the real PowerShell Gallery beyond its actual upstream release line (which is unrelated to this fork's own local development and already well past this pin). This repository's `Tools/build.requirements.psd1` pins a locally built `AtlassianPS.Standards` release, installed into a sibling `.local-modules/` directory outside every repo rather than the machine's real, shared module path, so it can never collide with a real installed copy. `Tools/setup.ps1` adds that directory to `$env:PSModulePath` for the current process only.

## Adding a check to a tier

Add a `-Tag 'CanaryRead'` or `-Tag 'CanaryWrite'` (in addition to a Context's or `It`'s existing tags) to an existing or new block inside `Tests/Integration/Configuration.Integration.Tests.ps1`, rather than a new file: Pester tags on `Context`/`It` combine with the enclosing `Describe`'s tags, so this is enough to add the check to a canary tier without duplicating the file's shared `BeforeAll` (credential/session setup) or `AfterAll` (cleanup). Keep read additions inexpensive -- that tier runs six times a day -- and keep write additions inside the existing disposable space/page lifecycle rather than creating a second one.
