
> **Fork notice:** ConfluencePSVII is a fork of [ConfluencePS](https://github.com/AtlassianPS/ConfluencePS) by the [AtlassianPS](https://github.com/AtlassianPS) team (MIT License), renamed and maintained by Gregory Machin. "VII" is only part of the name: it supports Windows PowerShell 5.1 and PowerShell 7.4+, and can be loaded side by side with the upstream module.
---
layout: module
permalink: /module/ConfluencePSVII/
---
# [ConfluencePSVII](https://atlassianps.org/module/ConfluencePS)

[![GitHub release](https://img.shields.io/github/release/GregoryMachin/ConfluencePSVII.svg?style=for-the-badge)](https://github.com/GregoryMachin/ConfluencePSVII/releases/latest)
[![Build Status](https://img.shields.io/github/actions/workflow/status/GregoryMachin/ConfluencePSVII/ci.yml?style=for-the-badge)](https://github.com/GregoryMachin/ConfluencePSVII/actions/workflows/ci.yml)
![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)

Automate your documentation! ConfluencePSVII is a PowerShell module that interacts with Atlassian's [Confluence] wiki product.

Need to add 100 new pages based on some dumb CSV file? Are you trying to figure out how to delete all pages labeled 'deleteMe'? Are you sick of manually editing the same page every single day? ConfluencePSVII has you covered!

ConfluencePSVII communicates with Atlassian's actively supported [REST API] via basic authentication. The REST implementation is the only way to interact with their cloud-hosted instances via API, and will eventually be the only way to interact with server installations.

Join the conversation on [![SlackLogo][] AtlassianPSVII.Slack.com](https://atlassianps.org/slack)

[SlackLogo]: https://atlassianps.org/assets/img/Slack_Mark_Web_28x28.png
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

You can find the full documentation on our [homepage](https://atlassianps.org/docs/ConfluencePS) and in the console.

```powershell
# Review the help at any time!
Get-Help about_ConfluencePSVII
Get-Help about_ConfluencePSVII_Authentication
Get-Command -Module ConfluencePSVII
Get-Help Get-ConfluencePage -Full   # or any other command
```

For first steps to get up and running, check out the [Getting Started](https://atlassianps.org/docs/ConfluencePS/#getting-started) page.
For Cloud, Data Center, Server, and anonymous authentication examples, see the [authentication guide](https://atlassianps.org/docs/ConfluencePS/about/authentication.html).

### Contribute

Want to contribute to AtlassianPSVII? Great!
We appreciate [everyone](https://atlassianps.org/#people) who invests their time to make our modules the best they can be.

Check out our guidelines on [Contributing](https://atlassianps.org/docs/Contributing/) to our modules and documentation.

## Tested on

| Configuration | Status |
| ------------- | ------ |
| Windows PowerShell v5.1 | [CI workflow](https://github.com/GregoryMachin/ConfluencePSVII/actions/workflows/ci.yml) |
| PowerShell 7 on Windows | [CI workflow](https://github.com/GregoryMachin/ConfluencePSVII/actions/workflows/ci.yml) |
| PowerShell 7 on Ubuntu | [CI workflow](https://github.com/GregoryMachin/ConfluencePSVII/actions/workflows/ci.yml) |
| PowerShell 7 on macOS | [CI workflow](https://github.com/GregoryMachin/ConfluencePSVII/actions/workflows/ci.yml) |

## Acknowledgements

* Thanks to [brianbunke] for getting this module on it's feet
* Thanks to [thomykay] for his [PoshConfluence] SOAP API module, which provided enough of a starting point to feel comfortable undertaking this project.
* Thanks to everyone ([Our Contributors](https://atlassianps.org/#people)) that helped with this module

## Useful links

* [Source Code]
* [Latest Release]
* [Submit an Issue]
* [Contributing]
* How you can help us: [List of Issues](https://github.com/GregoryMachin/ConfluencePSVII/issues?q=is%3Aissue+is%3Aopen+label%3Aup-for-grabs)

## Disclaimer

Hopefully this is obvious, but:
> This is an open source project (under the [MIT license]), and all contributors are volunteers. All commands are executed at your own risk. Please have good backups before you start, because you can delete a lot of stuff if you're not careful.

  [Confluence]: <https://www.atlassian.com/software/confluence>
  [REST API]: <https://docs.atlassian.com/atlassian-confluence/REST/latest/>
  [PowerShell Gallery]: <https://www.powershellgallery.com/>
  [thomykay]: <https://github.com/thomykay>
  [PoshConfluence]: <https://github.com/thomykay/PoshConfluence>
  [RamblingCookieMonster]: <https://github.com/RamblingCookieMonster>
  [PSStackExchange]: <https://github.com/RamblingCookieMonster/PSStackExchange>
  [Source Code]: <https://github.com/GregoryMachin/ConfluencePSVII>
  [Latest Release]: <https://github.com/GregoryMachin/ConfluencePSVII/releases/latest>
  [Submit an Issue]: <https://github.com/GregoryMachin/ConfluencePSVII/issues/new>
  [Contributing]: https://atlassianps.org/docs/Contributing/
  [juneb]: <https://github.com/juneb>
  [brianbunke]: <https://github.com/brianbunke>
  [Check this out]: <https://github.com/juneb/PowerShellHelpDeepDive>
  [MIT license]: <https://github.com/brianbunke/ConfluencePS/blob/master/LICENSE>

<!-- [//]: # (Sweet online markdown editor at http://dillinger.io) -->
<!-- [//]: # ("GitHub Flavored Markdown" https://help.github.com/articles/github-flavored-markdown/) -->
<!-- -->
