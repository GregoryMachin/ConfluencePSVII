# [ConfluencePSVII](https://github.com/GregoryMachin/ConfluencePSVII)

[![GitHub release](https://img.shields.io/github/release/GregoryMachin/ConfluencePSVII.svg?style=for-the-badge)](https://github.com/GregoryMachin/ConfluencePSVII/releases/latest)
[![Build Status](https://img.shields.io/github/actions/workflow/status/GregoryMachin/ConfluencePSVII/ci.yml?style=for-the-badge)](https://github.com/GregoryMachin/ConfluencePSVII/actions/workflows/ci.yml)
![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)

> **Fork notice:** ConfluencePSVII is a fork of [ConfluencePS](https://github.com/AtlassianPS/ConfluencePS) by the [AtlassianPS](https://github.com/AtlassianPS) team (MIT License), renamed and maintained by Gregory Machin. "VII" is only part of the name: it supports Windows PowerShell 5.1 and PowerShell 7.4+, and can be loaded side by side with the upstream module.

Automate your documentation! ConfluencePSVII is a PowerShell module that interacts with Atlassian's [Confluence] wiki product.

Need to add 100 new pages based on some dumb CSV file? Are you trying to figure out how to delete all pages labeled 'deleteMe'? Are you sick of manually editing the same page every single day? ConfluencePSVII has you covered!

ConfluencePSVII communicates with Atlassian's actively supported [REST API] via basic authentication. The REST implementation is the only way to interact with their cloud-hosted instances via API, and will eventually be the only way to interact with server installations.

<!--more-->

---

## Instructions

### Installation

ConfluencePSVII is not published to the PowerShell Gallery; use it straight from its repository:

```powershell
git clone https://github.com/GregoryMachin/ConfluencePSVII.git
Import-Module ./ConfluencePSVII/ConfluencePSVII/ConfluencePSVII.psd1
```

For the built release copy (merged module and compiled help) run `./Tools/setup.ps1` and
`Invoke-Build -Task Build` in the clone, then import `./Release/ConfluencePSVII/ConfluencePSVII.psd1`.

```powershell
# To use each session:
Import-Module ./ConfluencePSVII/ConfluencePSVII/ConfluencePSVII.psd1
$credential = Get-Credential -UserName 'me@example.com'
Set-ConfluenceInfo -BaseURI 'https://YourCloudWiki.atlassian.net/wiki' -Credential $credential
```

### Usage

The full documentation is in the [docs folder](https://github.com/GregoryMachin/ConfluencePSVII/tree/master/docs/en-US) and in the console.

```powershell
# Review the help at any time!
Get-Help about_ConfluencePSVII
Get-Help about_ConfluencePSVII_Authentication
Get-Command -Module ConfluencePSVII
Get-Help Get-ConfluencePage -Full   # or any other command
```

For first steps to get up and running, see `Get-Help about_ConfluencePSVII` or the [docs folder](https://github.com/GregoryMachin/ConfluencePSVII/tree/master/docs/en-US).
For Cloud, Data Center, Server, and anonymous authentication examples, see the [authentication guide](https://github.com/GregoryMachin/ConfluencePSVII/blob/master/docs/en-US/about_ConfluencePSVII_Authentication.md).

### Contribute

Want to contribute? Great!
Contributions are welcome: open an issue or a pull request in this repository.


## Tested on

| Configuration | Status |
| ------------- | ------ |
| Windows PowerShell v5.1 | [CI workflow](https://github.com/GregoryMachin/ConfluencePSVII/actions/workflows/ci.yml) |
| PowerShell 7 on Windows | [CI workflow](https://github.com/GregoryMachin/ConfluencePSVII/actions/workflows/ci.yml) |
| PowerShell 7 on Ubuntu | [CI workflow](https://github.com/GregoryMachin/ConfluencePSVII/actions/workflows/ci.yml) |
| PowerShell 7 on macOS | [CI workflow](https://github.com/GregoryMachin/ConfluencePSVII/actions/workflows/ci.yml) |

## Acknowledgements

* This module is a fork of [ConfluencePS](https://github.com/AtlassianPS/ConfluencePS); thanks to its original authors and contributors.

## Useful links

* [Source Code]
* [Latest Release]
* [Submit an Issue]
* How you can help us: [List of Issues](https://github.com/GregoryMachin/ConfluencePSVII/issues?q=is%3Aissue+is%3Aopen+label%3Aup-for-grabs)

## Disclaimer

Hopefully this is obvious, but:
> This is an open source project (under the [MIT license]), and all contributors are volunteers. All commands are executed at your own risk. Please have good backups before you start, because you can delete a lot of stuff if you're not careful.

  [Confluence]: <https://www.atlassian.com/software/confluence>
  [REST API]: <https://docs.atlassian.com/atlassian-confluence/REST/latest/>
  [PowerShell Gallery]: <https://www.powershellgallery.com/>
  [RamblingCookieMonster]: <https://github.com/RamblingCookieMonster>
  [PSStackExchange]: <https://github.com/RamblingCookieMonster/PSStackExchange>
  [Source Code]: <https://github.com/GregoryMachin/ConfluencePSVII>
  [Latest Release]: <https://github.com/GregoryMachin/ConfluencePSVII/releases/latest>
  [Submit an Issue]: <https://github.com/GregoryMachin/ConfluencePSVII/issues/new>
  [juneb]: <https://github.com/juneb>
  [Check this out]: <https://github.com/juneb/PowerShellHelpDeepDive>
  [MIT license]: <https://github.com/GregoryMachin/ConfluencePSVII/blob/master/LICENSE>

<!-- [//]: # (Sweet online markdown editor at http://dillinger.io) -->
<!-- [//]: # ("GitHub Flavored Markdown" https://help.github.com/articles/github-flavored-markdown/) -->
<!-- -->
