# Public Function Tests

This directory contains unit tests for public exported ConfluencePSVII cmdlets in `ConfluencePSVII/Public/*.ps1`.

## Naming

Use one file per public cmdlet named `<CmdletName>.Unit.Tests.ps1`.

Examples:

- `Invoke-Method.Unit.Tests.ps1` tests `ConfluencePSVII/Public/Invoke-Method.ps1`
- `Get-Page.Unit.Tests.ps1` tests `ConfluencePSVII/Public/Get-Page.ps1`

## Structure

Public cmdlet tests should usually include:

- Signature tests for parameters, types, defaults, and mandatory status when the public contract matters.
- Behavior tests that mock `Invoke-Method` and verify the REST method, URI, body, paging, and conversion behavior.
- Input validation tests for parameter sets, pipeline support, and expected error paths.

## Helpers

Dot-source shared test helpers with `../../Helpers/<HelperName>.ps1` from files in this directory.
Use `Initialize-TestEnvironment` in `BeforeDiscovery`, then test inside `InModuleScope ConfluencePSVII`.

See [`.template.ps1`](.template.ps1) for a starting point.
