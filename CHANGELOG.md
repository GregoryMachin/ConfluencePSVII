# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/),
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added

- Added Confluence Data Center integration-test infrastructure: `docker-compose.yml` (moveworkforward `atlas-run-standalone` image), `Tools/Wait-ConfluenceServer.ps1`, and `StartConfluenceDocker` / `StopConfluenceDocker` build tasks.
- Added `.github/workflows/integration_tests.yml` with parallel Cloud and Dockerized Data Center tracks (nightly schedule + manual dispatch input).
- Added `ConvertTo-ConfluenceStorageFormat -AsPlainText` to publish literal text containing wiki markup characters without Confluence converting them to links, mentions, or macros (#178, [@empty03]).
- Added `Get-ConfluenceServerInformation` to expose Confluence system information and deployment type.
- Added Confluence Cloud REST API v2 support (Phase 7): a deployment-aware private route resolver; `Invoke-ConfluenceMethod` now follows Cloud v2 pagination (opaque cursor via body `_links.next` or an RFC 5988 `Link` response header) alongside the existing v1/Data Center convention; new private response adapters that convert Cloud v2 page, space, attachment, version, and user shapes into the existing public types; and `Get-ConfluencePage -PageID`/`Get-ConfluenceChildPage`/`Get-ConfluenceSpace` now route to the Cloud v2 page, direct-children/descendants, and spaces endpoints when new `-BaseUri`/`-DeploymentType Cloud` parameters are supplied (via `Set-ConfluenceInfo` or explicitly). Without them, every command keeps its existing v1/Data Center behavior unchanged. `Get-ConfluencePage`'s `bySpace`/`byLabel`/`byQuery` parameter sets remain on v1 CQL/content-search routes on both deployments, since Cloud v2 has no CQL-search equivalent and filters its page collection by numeric space ID rather than space key. `Get-ConfluenceSpace` on Cloud v2 batches one or more `-SpaceKey` values into a single request via the collection's `keys` filter instead of one v1-style lookup per key. `Get-ConfluenceLabel` now also routes to the Cloud v2 label route the same way; `Add-ConfluenceLabel`/`Set-ConfluenceLabel`/`Remove-ConfluenceLabel` accept and forward the same `-BaseUri`/`-DeploymentType` parameters to their internal page/label lookups, but their own mutations always stay on the v1 route, since Cloud v2 has no page-label mutation operation at all. `Get-ConfluenceAttachment` now routes attachment metadata reads to Cloud v2, and `Remove-ConfluenceAttachment` now routes deletion to Cloud v2's dedicated attachment-delete route instead of the generic v1 content-delete route; uploading (`Add-ConfluenceAttachment`), updating (`Set-ConfluenceAttachment`), and downloading (`Get-ConfluenceAttachmentFile`) attachments always keep using the v1 route, since Cloud v2 has no equivalent operation for any of them. `New-ConfluencePage`, `Set-ConfluencePage`, and `Remove-ConfluencePage` now route page create/update/delete to Cloud v2: creation and updates resolve a target space key to its numeric `spaceId` through `Get-ConfluenceSpace` when needed, map a parent page to a single `parentId` field instead of a v1 `ancestors` array, and send the v2 request body shape (`body.representation`/`body.value` directly, not nested under a representation key like v1); `Set-ConfluencePage` still reads the current version number first and increments it, so a conflicting concurrent edit is rejected by Confluence's own optimistic concurrency check on the submitted version number, the same as the v1 path relies on. `New-ConfluenceSpace` now routes space creation to Cloud v2 as well, sending the v2 request's flat description shape and converting the response with a new `ConvertTo-ConfluenceSpaceV2` call path; `Remove-ConfluenceSpace` and `ConvertTo-ConfluenceStorageFormat` were reviewed and intentionally left on the v1 route on every deployment, since Cloud v2 has no space-delete operation and its only storage-conversion replacement is asynchronous, which would change `ConvertTo-ConfluenceStorageFormat`'s synchronous output contract.
- Added Confluence blog post support (Phase 8, Task 50): `Get-ConfluenceBlogPost`, `New-ConfluenceBlogPost`, `Set-ConfluenceBlogPost`, and `Remove-ConfluenceBlogPost`, plus a new `ConfluencePS.BlogPost` type and `ConvertTo-ConfluenceBlogPost`/`ConvertTo-ConfluenceBlogPostV2` converters. This is a first-class new command family, not a migration of existing behavior: it supports v1 (`/content` filtered to `type=blogpost`) on both deployments and, when `-BaseUri`/`-DeploymentType Cloud` are supplied, Cloud v2's dedicated `/blogposts` collection, using the same route-resolver/converter/opt-in-parameter architecture the Phase 7 page and space commands established. A blog post has no parent or ancestors, so creation and updates always resolve a target space (by key, via `Get-ConfluenceSpace`, or a `-Space`/`InputObject.Space` object) but never build an `ancestors`/`parentId` mapping the way page commands do. `Get-ConfluenceBlogPost`'s `byQuery` parameter set stays on the v1 CQL search route, since Cloud v2 has no equivalent, the same parity gap `Get-ConfluencePage` already documents.
- Added Confluence comment support (Phase 8, Task 51): `Get-`/`New-`/`Set-`/`Remove-ConfluenceFooterComment` and `Get-`/`New-`/`Set-`/`Remove-ConfluenceInlineComment`, plus a new `ConfluencePS.Comment` type (with a `Type` property recording `footer` or `inline`) and `ConvertTo-ConfluenceComment`/`ConvertTo-ConfluenceCommentV2` converters. Footer comments follow the same v1 (generic `type=comment` content)/Cloud v2 opt-in (`/footer-comments`) architecture as blog posts, and support replies via `-ParentCommentID`/`parentCommentId`. Inline (text-anchored) comments are read and updated the same way, but creation is Cloud v2-only: `New-ConfluenceInlineComment` has no `-DeploymentType` parameter and requires `-BaseUri`, since Confluence's v1/Data Center content API has no operation for anchoring a comment to specific page text, only generic page comments; it accepts `-TextSelection` (the exact page text to anchor to) plus optional `-TextSelectionMatchCount`/`-TextSelectionMatchIndex` to disambiguate a repeated phrase, mapped directly into Cloud v2's `inlineCommentProperties`. `Get-ConfluenceInlineComment`'s v1 path is a documented approximation: Confluence's classic content API cannot distinguish an inline comment from a footer comment, so it returns the same items `Get-ConfluenceFooterComment`'s v1 path would for the same page; only the Cloud v2 opt-in reads the actually dedicated inline-comments collection.
- Added Confluence hierarchy and version-history read commands (Phase 8, Task 52): `Get-ConfluencePageAncestor` returns a page's ancestor chain in root-to-parent order (minimal ID/Status/Title objects, matching the existing partial shape `Get-ConfluencePage -Ancestors` has always used), and `Get-ConfluencePageVersion` returns either the full version-history list for a page or, with `-VersionNumber`, a single historical revision (optionally including its content via `-IncludeBody`, useful for diffing against the current page or planning a rollback). Both follow the same v1/Cloud-v2-opt-in architecture as the rest of Phase 7/8; child and descendant page reads already existed via `Get-ConfluenceChildPage` (Task 44), so this task did not duplicate them. `Get-ConfluencePageVersion -VersionNumber`'s Cloud v2 response shape is inferred from the main page v2 response's field conventions and has not been live-verified against a Cloud tenant.
- Added read-only `Get-ConfluenceDatabase`, `Get-ConfluenceFolder`, and `Get-ConfluenceWhiteboard` (Phase 8, Task 53) exposing three Confluence Cloud modern content types -- databases (Smart Links-backed embedded database views), folders (organizational content containers), and whiteboards (visual canvas content) -- plus new `ConfluencePS.Database`/`ConfluencePS.Folder`/`ConfluencePS.Whiteboard` types and `ConvertTo-ConfluenceDatabaseV2`/`ConvertTo-ConfluenceFolderV2`/`ConvertTo-ConfluenceWhiteboardV2` converters. All three are Cloud v2-only content types with no v1/Data Center equivalent at all, so none of these commands have a `-DeploymentType` parameter and all three require `-BaseUri`; none of the types has a `Body` property, since none of them is text content. No write commands exist for any of them yet, per this task's own scope of proving the read models stable first. The response field conventions for all three are inferred from Cloud v2's shared content-type conventions and have not been live-verified.
- Added `Get-ConfluenceInlineTask` and `Set-ConfluenceInlineTask` (Phase 8, Task 54) exposing Confluence inline tasks (the checkbox action items embedded in a page's body) as a queryable, updatable resource, plus a new `ConfluencePS.InlineTask` type and `ConvertTo-ConfluenceInlineTaskV2` converter. Like the Task 53 content types, inline tasks have no v1/Data Center equivalent as a separate resource at all -- neither command has a `-DeploymentType` parameter and both require `-BaseUri`. `Get-ConfluenceInlineTask` filters by page, space, status, assignee, creator, and creation/due date ranges; `Set-ConfluenceInlineTask` marks a task `complete` or reopens it to `incomplete`, reading the current version number first and incrementing it so a conflicting concurrent edit is rejected the same way every other write command in this module works -- only `-Status` is mutable through this command, since the task's text/assignee/due date are edited through the owning page's body. Missing assignee, completer, due date, and completed date are left unset rather than erroring, since an open, unassigned task legitimately has none of them. The response field conventions are inferred from Cloud v2's shared content-type conventions and have not been live-verified.
- Added `Get-ConfluenceSpacePermission` (Phase 8, Task 55, permissions family) exposing every currently effective permission grant on a Confluence Cloud space -- each grant's principal (a user, a group, or a space role) and the operation they are granted -- plus a new `ConfluencePS.SpacePermission` type and `ConvertTo-ConfluenceSpacePermissionV2` converter. Space permission grants have no v1/Data Center equivalent, so this command has no `-DeploymentType` parameter and requires `-BaseUri`. This family is deliberately read-only: Cloud v2 does not expose a way to add or remove an individual permission grant directly, only space role assignments, which the next Task 55 commit adds. The response field conventions are inferred from Cloud v2's shared content-type conventions and have not been live-verified.
- Added `Get-`/`New-`/`Set-`/`Remove-ConfluenceSpaceProperty` (Phase 8, Task 55, space properties family) exposing Confluence Cloud space properties -- arbitrary JSON key/value metadata attached to a space -- plus a new `ConfluencePS.SpaceProperty` type and `ConvertTo-ConfluenceSpacePropertyV2` converter. Like the other Task 53/54 content types, space properties have no v1/Data Center equivalent at all, so none of these commands have a `-DeploymentType` parameter and all require `-BaseUri`. `Get-SpaceProperty` filters by property ID or by key, or lists every property on a space; `Set-SpaceProperty` reads the current version first (via `Get-SpaceProperty`) and increments it before writing, the same optimistic-concurrency pattern every other write command in this module uses. Ported JiraPS's entity-property security policy (Tasks 30-39's `Get-`/`Set-`/`Remove-JiraIssueProperty`/`JiraProjectProperty`) to Confluence as new `Assert-ConfluencePropertyKey`/`Assert-ConfluencePropertyDataKey`/`ConvertTo-ConfluenceSafePropertyValue`/`ConvertTo-ConfluencePropertyJson` helpers: `New-ConfluenceSpaceProperty` and `Set-ConfluenceSpaceProperty` reject a key or any nested value key that looks like it is meant to carry a secret (password, token, credential, API key, ...), reject credentials/secure strings/script blocks outright, and cap a serialized value at 32,768 UTF-8 bytes, all before a request is ever sent -- space properties must never be used to store secrets. The response field conventions are inferred from Cloud v2's shared content-type conventions and have not been live-verified.

### Changed

- Updated the shared build dependency and workflow action pins to `AtlassianPS.Standards` `0.1.11`.
- Documented how to authenticate to Confluence Cloud with an Atlassian account email address and API token, including a dedicated authentication about topic (#203, #248, [@lipkau]).
- Migrated `Tools/setup.ps1` and `Tools/update.dependencies.ps1` to shared `AtlassianPS.Standards` bootstrap/update commands with deterministic standards-version resolution from `Tools/build.requirements.psd1`.
- Replaced legacy PSDepend hashtable dependencies with pinned array requirements and aligned workflow setup action usage to the pinned standards action release.
- `Set-ConfluenceInfo` now accepts AtlassianPS.Configuration server entries with explicit Confluence deployment/authentication metadata, normalizes Cloud API URIs to `/wiki/rest/api`, preserves Data Center context paths, and rejects conflicting product or OAuth metadata.
- `Set-ConfluencePage` now forwards `Version.Message` for `-InputObject` / pipeline updates when provided (#207, #231, [@JoseAPortilloJSC])
- CI smoke tests now run the dedicated `Smoke` integration tag and fail fast when required Confluence Cloud integration settings are missing.
- `integration_tests.yml` now runs real Cloud and Data Center integration jobs (instead of a scaffold marker), matching the JiraPS track model.
- Integration test setup now follows the JiraPS `.env.example` model, including automatic `.env` loading and explicit Cloud (`CONFLUENCE_CLOUD_URL`, `ATLASSIAN_CLOUD_USER`, `ATLASSIAN_CLOUD_PAT`) vs DataCenter (`CI_CONFLUENCE_*`) track variable contracts.

### Fixed

- `Get-ConfluenceAttachmentFile` now preserves attachment download URLs when server information is unavailable, restoring Data Center attachment downloads in the Dockerized integration track.
- `Get-ConfluenceSpace` no longer requests unused space label metadata, avoiding HTTP 500 responses from Confluence Data Center 8.9.x when listing spaces (#214)
- `Get-ConfluencePage -Label` now quotes label values in generated CQL so labels containing hyphens are accepted by Confluence (#175, #185, [@ehrenfeu])
- Fixed pagination so GET filters such as `spaceKey` and `title` are preserved when requesting follow-up pages (#157).
- `Get-ConfluencePage -Label` now returns only current pages by default and supports `-Status` to request one or more page statuses (#213)
- `Invoke-Method` now handles JSON payloads with duplicate key casing (for example `subType` and `subtype`) without failing parsing (#216, [@codethief])
- Fixed `-PersonalAccessToken` authentication on PowerShell 6+ by forwarding it as a bearer authorization header (#208, #209, [@sebmaurer])
- Fixed Confluence Cloud attachment downloads on PowerShell 6+ by preserving authorization across Atlassian download redirects.
- `Set-ConfluenceInfo` now preserves configured defaults when called from inside another function (#199, [@lipkau]).
- `Invoke-ConfluenceMethod -First` now actually limits the number of returned results and stops following pagination links once satisfied, instead of being silently ignored; help previously and incorrectly noted it as "Not yet implemented".
- `Invoke-ConfluenceMethod` no longer loops forever if a server returns the same pagination link twice in a row, and caps total pagination depth.
- `ConvertTo-ConfluenceAttachment` (the private v1 attachment converter) now correctly resolves `PageID` from the response; it previously always resolved to `$null`/`0` because of an unbound `$_` reference outside a `Select-Object` scriptblock, so `Attachment.PageID` and the sanitized `Attachment.Filename` were silently wrong for every attachment.
- `Set-ConfluenceInfo` no longer defaults its own `-BaseURi` parameter through `PSDefaultParameterValues`. `Get-Command -Module` returns both a prefixed and an unprefixed `CommandInfo` for every function when queried from inside the module, and the unprefixed one's default `ToString()` conversion reconstructs the prefixed command name; without excluding both, a later parameterless `Set-ConfluenceInfo` call would have silently reused the previous base URI instead of clearing configuration, once any command declared a `-BaseUri` parameter (Task 44).
- Corrected the stale function-count summary in `docs/api-contract-inventory.md` (it had read 45 functions/22 public/23 private since it was first recorded, but the private helper count had grown to 37 across Tasks 41-49 without the summary being updated); it now reads 63/26/37, matching the table rows the automated inventory test already enforced.

### Fixed

- Fixed `-Label` parsing for the Get-ConfluencePage cmdlet (#193 [@claudiospizzi])

## [2.5] 2019-03-27

### Added

- Added support for authenticating with X509Certificate (#164, [@ritzcrackr])

### Fixed

- Conversion of pageID attribute of Attachments to `[Int]` (#166, [@lipkau])
- Fixed generation of headers in tables when using `ConvertTo-ConfluenceTable` (#163, [@lipkau])

## [2.4] 2018-12-12

### Added

- Added `-Vertical` to `ConvertTo-Table` (#148, [@brianbunke])
- Added support for TLS1.2 (#155, [@lipkau])

### Changed

- Changed productive module files to be compiled into single `.psm1` file (#133, [@lipkau])
- Fixed `ConvertTo-Table` for empty cells (#144, [@FelixMelchert])
- Changed CI/CD pipeline from AppVeyor to Azure DevOps (#150, [@lipkau])
- Fixed trailing slash in ApiURi parameter (#153, [@lipkau])

## [2.3] 2018-03-22

### Added

- custom object type for Attachments: `ConfluencePS.Attachment` (#123, [@JohnAdders][])
- `Add-Attachment`: upload a file to a page (#123, [@JohnAdders][])
- `Get-Attachment`: list all attachments of a page (#123, [@JohnAdders][])
- `Get-AttachmentFile`: download an attachment to the local disc (#123, [@JohnAdders][])
- `Remove-Attachment`: remove an attachment from a page (#123, [@JohnAdders][])
- `Set-Attachment`: update an attachment of a page (#123, [@JohnAdders][])
- `-InFile` to `Invoke-Method` for uploading of files with `form-data` (#130, [@lipkau][])
- full support for PowerShell Core (`pwsh`) (#119, [@lipkau][])
- AppVeyor tests on PowerShell v6 (Linux) (#119, [@lipkau][])
- AppVeyor tests on PowerShell v6 (Windows) (#119, [@lipkau][])

### Changed

- Made `Invoke-Method` public (#130, [@lipkau][])
- Moved Online Help of cmdlets to the homepage (#130, [@lipkau][])
- Updated help for contributing to the project (#130, [@lipkau][])
- Documentation for the custom classes of the module (#107, [@lipkau][])
- Tests now run from `./Release` Path (#99, [@lipkau][])
- Have the Build script to "compile" the functions into the psm1 file (enhances performance) (#119, [@lipkau][])
- Have a zip file deploy as artifact of the release (#90, [@lipkau][])

## [2.2] - 2018-01-01

### Added

- Automatic deployment of documentation to website (#120, [@lipkau][])
- New parameter `-Query` to `Get-Page` for complex searches (#106, [@lipkau][])
- Documentation for the custom classes of the module (#107, [@lipkau][])
- Added full support for PowerShell Core (`pwsh`) (#119, [@lipkau][])

### Changed

- Fixed encoding of Unicode chars (#101, [@lipkau][])
- Require necessary Assembly for HttpUtility (#102, [@lipkau][])

## [2.1] - 2017-11-01

### Changed

- Shows a warning when the server requires a CAPTCHA for the authentication (#91, [@lipkau][])
- Custom classes now print relevant data in `ToString()` (#92, [@lipkau][])

## [2.0] - 2017-08-17

A new major version! ConfluencePS has been totally refactored to introduce new features and greatly improve efficiency.

"A new major version" means limited older functionality was intentionally broken. In addition, there are a ton of good changes, so some big picture notes first:

- All functions changed from "Wiki" prefix to "Confluence", like `Get-ConfluencePage`
  - But the module accommodates for any prefix you want, e.g. `Import-Module ConfluencePS -Prefix Wiki`
- Functions changed or removed:
  - `Get-WikiLabelApplied` [removed; functionality added to `Get-ConfluencePage -Label foo`]
  - `Get-WikiPageLabel` > `Get-ConfluenceLabel`
  - `New-WikiLabel` > `Add-ConfluenceLabel`
- `Get-*` functions now support paging, and defining your preferred page size
- `-Limit` and `-Expand` parameters were removed from functions
  - With paging implementation, modifying the returned object limit isn't necessary
  - And allows for richer objects to be returned by default
- `-ApiUri` and `-Credential` parameters added to every function
  - This is useful if you have more than one Confluence instance
  - `Set-ConfluenceInfo` now defines `ApiUri` and `Credential` defaults for the current session
  - And you can override any single function:
  - `Get-ConfluenceSpace -ApiUri 'https://wiki2.example.com' -Credential (Get-Credential)`
- All functions now output custom object types, like `[ConfluencePS.Page]`
  - Allows for returning more object properties...
  - ...and only displaying the most relevant in the default output
  - Also enables a much improved pipeline flow
  - This behavior removed the need for the `-Expand` parameter
- Private functions are leveraged heavily to reduce repeat code
  - `Invoke-Method` is the most prominent example

If you like drinking from the fire hose, here's [everything we closed for 2.0], because we probably forgot to list something here. Otherwise, read on for summarized details.

### Added

- All `Get-*` functions now support paging
- `-ApiUri` and `-Credential` parameters added to functions
  - `Set-ConfluenceInfo` behavior is mostly unchanged (see below)
- Objects returned are now custom typed, like `[ConfluencePS.Page]`
  - Try piping ConfluencePS objects into `Format-List *` to see all properties

### Changed

- Function prefix defaults to "Confluence" instead of "Wiki" (`Get-ConfluenceSpace`)
  - If you like "Wiki", you can `Import-Module ConfluencePS -Prefix Wiki`
- `Add-ConfluenceLabel`
  - Name used to be `New-WikiLabel`
  - The "Add" verb better reflects the function's behavior
- `Get-ConfluenceChildPage`
  - Default behavior returns only immediate child pages. Which also means...
  - Added `-Recurse` to return all pages below the given page, not just immediate child objects
    - NOTE: Recurse is not available in on-premise installs right now, only Atlassian cloud instances
  - `-ParentID` > `-PageID`
- `Get-ConfluenceLabel`
  - Name used to be `Get-WikiPageLabel`
  - Now returns `[ConfluencePS.ContentLabelSet]` objects
    - Which are relationships of `[ConfluencePS.Label]` & `[ConfluencePS.Page]` objects
- `Get-ConfluencePage`
  - `Get-ConfluencePage` (with no parameters) doesn't work anymore
    - With paging supported, this would be a ton of pages
    - `Get-ConfluenceSpace | Get-ConfluencePage` still works, if you really need it
  - Now returns `[ConfluencePS.Page]` objects
  - New `-Label` parameter filters returned pages by applied label(s)
  - New `-Space` parameter accepts Space objects
- `Get-ConfluenceSpace`
  - Now returns `[ConfluencePS.Space]` objects
  - `-Key` renamed to `-SpaceKey` ("Key" still works as an alias)
  - `-Name` parameter removed
- `New-ConfluencePage`
  - New `-Parent` parameter accepts Page objects
  - New `-Space` parameter accepts Space objects
- `New-ConfluenceSpace`
  - `-Key` renamed to `-SpaceKey` ("Key" still works as an alias)
- `Set-ConfluenceInfo`
  - Now adds the URI/Credential to `$PSDefaultParameterValues`
    - `-ApiUri` & `-Credential` parameters now exist on every function
    - `Set-ConfluenceInfo` defines their defaults for the current session
    - Meaning they could still be overwritten on any single command
  - No longer automatically prompts for credentials if `-Credential` is absent
    - Allows for anonymous authentication to public instances
  - New `-PromptCredentials` parameter displays a `Get-Credential` dialog while connecting
  - New `-PageSize` parameter optionally defines default page size for the session
- `Set-ConfluencePage`
  - Now returns `[ConfluencePS.Page]` objects
  - `-CurrentVersion` parameter removed (determined and incremented automatically now)
  - New `-Parent` parameter accepts Page objects

### Removed

- `-Limit` and `-Expand` parameters
  - `Get-*` function paging removes the need for fiddling with returned object limits
  - Custom object types hold relevant properties, removing the need to manually "expand" results
- `Get-WikiLabelApplied`
  - Functionality replaced with `Get-ConfluencePage -Label foo`

### Much ❤

[@lipkau](https://github.com/lipkau) refactored the entire module, and is the only reason `2.0` is a reality. In short, he is amazing. Thank you!

## [1.0].0-69 - 2016-11-28

No changelog available for version `1.0` of ConfluencePS. `1.0` was created in late 2015. Version `.69` was published to the PowerShell Gallery in Nov 2016, and it remained unchanged until `2.0`. If you're looking for things that changed prior to `2.0`...sorry, but these probably aren't the droids you're looking for. :)

[everything we closed for 2.0]: https://github.com/AtlassianPS/ConfluencePS/issues?utf8=%E2%9C%93&q=closed%3A2017-04-01..2017-08-17
[@alexsuslin]: https://github.com/alexsuslin
[@axxelG]: https://github.com/axxelG
[@beaudryj]: https://github.com/beaudryj
[@brianbunke]: https://github.com/brianbunke
[@Clijsters]: https://github.com/Clijsters
[@colhal]: https://github.com/colhal
[@Dejulia489]: https://github.com/Dejulia489
[@ebekker]: https://github.com/ebekker
[@empty03]: https://github.com/empty03
[@ehrenfeu]: https://github.com/ehrenfeu
[@FelixMelchert]: https://github.com/FelixMelchert
[@jkknorr]: https://github.com/jkknorr
[@JohnAdders]: https://github.com/JohnAdders
[@JoseAPortilloJSC]: https://github.com/JoseAPortilloJSC
[@kittholland]: https://github.com/kittholland
[@LiamLeane]: https://github.com/LiamLeane
[@lipkau]: https://github.com/lipkau
[@lukhase]: https://github.com/lukhase
[@padgers]: https://github.com/padgers
[@ritzcrackr]: https://github.com/ritzcrackr
[@ThePSAdmin]: https://github.com/ThePSAdmin
