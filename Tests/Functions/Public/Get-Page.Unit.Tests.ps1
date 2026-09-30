#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Get-Page" -Tag 'Unit' {
        BeforeEach {
            $script:lastCql = $null
            $script:lastUri = $null

            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param(
                    [string]$Uri,
                    [hashtable]$GetParameters
                )

                $script:lastUri = $Uri
                $script:lastCql = $GetParameters['cql']
                [ConfluencePSVII.Page]::new()
            }
        }

        It "builds one quoted label clause per label value for byLabel queries" {
            $null = Get-Page -ApiUri "https://example.com/wiki/rest/api" -Label @("labelA", "labelB")

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/search"
            $script:lastCql | Should -Be 'type=page AND label="labelA" AND label="labelB"'
        }

        It "builds one quoted label clause for a single byLabel value" {
            $null = Get-Page -ApiUri "https://example.com/wiki/rest/api" -Label @("labelA")

            $script:lastCql | Should -Be 'type=page AND label="labelA"'
        }

        It "quotes hyphenated label values in byLabel queries" {
            $null = Get-Page -ApiUri "https://example.com/wiki/rest/api" -Label "noarchive-single"

            $script:lastCql | Should -Be 'type=page AND label="noarchive-single"'
        }

        It "appends space filtering to multi-label byLabel queries" {
            $null = Get-Page -ApiUri "https://example.com/wiki/rest/api" -SpaceKey "HOTH" -Label @("labelA", "labelB")

            $script:lastCql | Should -Be 'type=page AND label="labelA" AND label="labelB" AND space=HOTH'
        }

        It "returns only current pages by default for byLabel results" {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                $currentPage = [ConfluencePSVII.Page]::new()
                $currentPage.ID = 1
                $currentPage.Status = 'current'

                $trashedPage = [ConfluencePSVII.Page]::new()
                $trashedPage.ID = 2
                $trashedPage.Status = 'trashed'

                $archivedPage = [ConfluencePSVII.Page]::new()
                $archivedPage.ID = 3
                $archivedPage.Status = 'archived'

                $currentPage, $trashedPage, $archivedPage
            }

            $result = Get-Page -ApiUri "https://example.com/wiki/rest/api" -Label "labelA"

            $result | Should -HaveCount 1
            $result.ID | Should -Be 1
        }

        It "returns pages matching the requested byLabel status values" {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                $currentPage = [ConfluencePSVII.Page]::new()
                $currentPage.ID = 1
                $currentPage.Status = 'current'

                $trashedPage = [ConfluencePSVII.Page]::new()
                $trashedPage.ID = 2
                $trashedPage.Status = 'trashed'

                $archivedPage = [ConfluencePSVII.Page]::new()
                $archivedPage.ID = 3
                $archivedPage.Status = 'archived'

                $currentPage, $trashedPage, $archivedPage
            }

            $result = Get-Page -ApiUri "https://example.com/wiki/rest/api" -Label "labelA" -Status current, trashed

            $result | Should -HaveCount 2
            $result.ID | Should -Be 1, 2
        }

        It "prefixes byQuery CQL with type=page without pre-encoding" {
            $null = Get-Page -ApiUri "https://example.com/wiki/rest/api" -Query 'space=HOTH and title~"*Object"'

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/search"
            $script:lastCql | Should -Be 'type=page AND space=HOTH and title~"*Object"'
        }

        It "throws when Label is an empty array" {
            { $null = Get-Page -ApiUri "https://example.com/wiki/rest/api" -Label @() } | Should -Throw

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It
        }

        It "sets prefixed defaults when called from inside a function" {
            function Set-TestConfluenceDefaults {
                Set-Info -BaseUri "https://example.com/wiki"
            }

            Set-TestConfluenceDefaults

            $script:PSDefaultParameterValues["Get-ConfluencePage:ApiUri"] | Should -Be "https://example.com/wiki/rest/api"
        }

        Context "Cloud v2 byId routing" {
            BeforeEach {
                Mock Invoke-Method -ModuleName ConfluencePSVII {
                    param([Uri]$Uri, [hashtable]$GetParameters)

                    $script:lastUri = $Uri.AbsoluteUri
                    $script:lastGetParameters = $GetParameters
                    ConvertFrom-Json '{"id": "100", "status": "current", "title": "Example", "body": {"storage": {"value": "<p>Hi</p>"}}}'
                }
            }

            It "routes a byId request to the v2 page route and converts the v2 shape" {
                $result = Get-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 100

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/pages/100"
                $result | Should -BeOfType [ConfluencePSVII.Page]
                $result.ID | Should -Be 100
                $result.Body | Should -Be '<p>Hi</p>'
            }

            It "requests body-format=storage unless -ExcludePageBody is set" {
                $null = Get-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 100

                $script:lastGetParameters['body-format'] | Should -Be 'storage'
            }

            It "omits body-format when -ExcludePageBody is set" {
                $null = Get-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 100 -ExcludePageBody

                $script:lastGetParameters.ContainsKey('body-format') | Should -BeFalse
            }

            It "requests one v2 route per PageID" {
                $null = Get-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 100, 200

                Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 2 -Scope It
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = Get-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -PageID 100

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/100"
            }

            It "uses the v1 route for Data Center regardless of -BaseUri" {
                $null = Get-Page -ApiUri "https://dc.example.com/rest/api" -BaseUri "https://dc.example.com" -DeploymentType DataCenter -PageID 100

                $script:lastUri | Should -Be "https://dc.example.com/rest/api/content/100"
            }
        }
    }
}
