# ConfluencePSVII current state

Reviewed: 2026-07-27

## Purpose

`ConfluencePSVII` is a PowerShell module for automating Confluence pages, spaces, labels, and attachments.
It supports Confluence Cloud and self-managed Confluence through a common cmdlet surface.

## How it works

- The manifest is version `2.5`, declares PowerShell 3.0, and uses the `Confluence` default prefix.
- Twenty-two public source files provide configuration, REST transport, content conversion, and CRUD cmdlets.
- Twenty-three private files implement converters, pagination, error handling, TLS/auth compatibility, and a wrapped `Invoke-WebRequest`.
- `Set-ConfluenceInfo` converts a base URI into a default `/rest/api` URI.
  Cloud callers are expected to provide a base URI ending in `/wiki`.
- Public cmdlets call `Invoke-Method`, which builds requests, handles credentials/certificates/PATs, converts JSON, follows `_links.next`, retries, and maps results.
- Page create/update uses Confluence storage-format bodies and version-number increments.
- Current Cloud operations use the v1 `/wiki/rest/api` family; Data Center uses the corresponding `/rest/api` family.

Snapshot: branch `master`, last local commit `e04e4ab` dated 2026-05-31.

## Testing and delivery

- 26 `*.Tests.ps1` files are present: 14 named unit-test files and 5 integration-test files, plus build/help/example/manifest suites.
- Unit coverage includes transport, converters, pagination, public commands, and a public-cmdlet coverage baseline.
- Cloud smoke tests run in CI when secrets are available.
- A scheduled/manual workflow runs Cloud tests and Dockerized Confluence Data Center tests.
- CI also tests Windows PowerShell 5.1 and PowerShell 7 on Windows, Ubuntu, and macOS.
- Build dependencies pin Pester 5.7.1 and PSScriptAnalyzer 1.25.0.

## Current strengths

- HTTP calls are centralized behind a mockable transport.
- Authentication supports Cloud email/API-token credentials and Data Center personal access tokens.
- Attachment redirects, transient failures, duplicate JSON key casing, and pagination filters have regression coverage.
- Cloud and Data Center integration tracks exist.
- Storage-format and page-version behavior is explicit.

## Gaps and risks

1. Confluence Cloud content operations still target REST API v1.
   Many v1 endpoints with v2 equivalents were scheduled for removal from public service after 2025-03-31, so Cloud compatibility needs endpoint-by-endpoint verification.
2. Cloud REST API v2 changes resource shapes and uses cursor pagination.
   A simple base-path replacement is not sufficient.
3. `PowerShellVersion = '3.0'` conflicts with the effective CI/runtime baseline and prevents use of safer modern language/runtime features.
4. The source manifest remains at the 2019 `2.5` release while a large unreleased modernization set exists.
5. OAuth 2.0 authorization-code support and scoped-token guidance are absent; bearer PAT behavior is primarily Data Center-oriented.
6. Cloud and Data Center behavior share transport and models too tightly for rapidly diverging APIs.
7. The module does not appear to surface Atlassian `Deprecation`, `Sunset`, `Link`, or rate-limit headers as actionable telemetry.
8. Data Center tests are valuable for current users, but affected Data Center products reach end of life in 2029; Cloud work should receive priority.

## Recommended update plan

### Urgent

1. Build an operation-level compatibility matrix for all 22 public commands against Cloud v2 and the supported Data Center REST API.
2. Introduce a deployment-aware route adapter:
   Cloud content routes use `/wiki/api/v2`; Data Center retains `/rest/api`.
3. Implement cursor pagination from v2 response links and add contract fixtures for every collection shape.
4. Migrate read-only commands first (`Get-Page`, `Get-ChildPage`, `Get-Space`, labels, attachments), then writes with version/conflict tests.
5. Add live Cloud canaries for create/read/update/delete page, attachment, label, and space behavior.

### Next

6. Raise the declared minimum to PowerShell 5.1 in a major release, or explicitly restore PowerShell 3 CI if it is genuinely supported.
7. Create separate Cloud v2 and Data Center DTO converters behind stable public output types.
8. Add OAuth 2.0 (3LO) token injection/refresh extensibility and document scoped API-token use.
9. Capture redacted response metadata for request IDs, rate limits, retry-after, deprecation, and sunset headers.
10. Release the accumulated changes with a migration guide and a clearly stated Cloud/Data Center support matrix.
11. Plan eventual Data Center maintenance-mode support in line with Atlassian's 2029 end-of-life date.

## Primary platform references

- Confluence Cloud REST API v2: <https://developer.atlassian.com/cloud/confluence/rest/v2/intro/>
- Confluence Cloud changelog: <https://developer.atlassian.com/cloud/confluence/changelog/>
- Confluence Data Center REST API: <https://developer.atlassian.com/server/confluence/confluence-rest-api-examples/>
- Atlassian REST API deprecation headers: <https://developer.atlassian.com/platform/marketplace/atlassian-rest-api-policy/>
- Data Center end of life: <https://www.atlassian.com/licensing/data-center-end-of-life>

## Review boundary

This was a static review of source, tests, documentation, build scripts, and workflows.
No authenticated Cloud/Data Center tests were executed.
