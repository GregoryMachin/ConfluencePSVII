#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Set-Page" -Tag 'Unit' {
        BeforeAll {
            $script:lastRequestBody = $null
            Mock Invoke-Method -ModuleName ConfluencePS {
                param(
                    [string]$Body
                )

                $script:lastRequestBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                [ConfluencePS.Page]::new()
            }
        }

        It "includes version.message from input object even when unchanged" {
            $page = [ConfluencePS.Page]::new()
            $page.ID = 42
            $page.Title = "Page title"
            $page.Body = "<p>Body</p>"
            $page.Version = [ConfluencePS.Version]::new()
            $page.Version.Number = 7
            $page.Version.Message = "Same message on purpose"

            $null = Set-Page -ApiUri "https://example.com/wiki/rest/api" -InputObject $page -Confirm:$false

            $script:lastRequestBody.version.number | Should -Be 8
            $script:lastRequestBody.version.message | Should -Be "Same message on purpose"
        }

        It "omits version.message when input object message is not provided" {
            $page = [ConfluencePS.Page]::new()
            $page.ID = 43
            $page.Title = "Page title"
            $page.Body = "<p>Body</p>"
            $page.Version = [ConfluencePS.Version]::new()
            $page.Version.Number = 2

            $null = Set-Page -ApiUri "https://example.com/wiki/rest/api" -InputObject $page -Confirm:$false

            $script:lastRequestBody.version.number | Should -Be 3
            $script:lastRequestBody.version.PSObject.Properties.Name | Should -Not -Contain "message"
        }

        Context "Cloud v2 routing" {
            BeforeEach {
                Mock Invoke-Method -ModuleName ConfluencePS {
                    param([Uri]$Uri, [string]$Body)
                    $script:lastUri = $Uri.AbsoluteUri
                    $script:lastRequestBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                    ConvertFrom-Json '{"id": "42", "status": "current", "title": "Example"}'
                }
                Mock Get-Page -ModuleName ConfluencePS {
                    $page = [ConfluencePS.Page]::new()
                    $page.ID = 42
                    $page.Title = "Original title"
                    $page.Body = "<p>Original body</p>"
                    $page.Version = [ConfluencePS.Version]::new()
                    $page.Version.Number = 7
                    $page
                }
            }

            It "routes byParameters updates to the v2 pages route with the flat body shape" {
                $result = Set-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 42 -Title "New title" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/pages/42"
                $script:lastRequestBody.id | Should -Be '42'
                $script:lastRequestBody.title | Should -Be 'New title'
                $script:lastRequestBody.body.representation | Should -Be 'storage'
                $script:lastRequestBody.version.number | Should -Be 8
                $result | Should -BeOfType [ConfluencePS.Page]
            }

            It "forwards -BaseUri and -DeploymentType to the internal Get-Page lookup" {
                $null = Set-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 42 -Title "New title" -Confirm:$false

                Should -Invoke -CommandName Get-Page -ModuleName ConfluencePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $BaseUri -eq "https://example.atlassian.net" -and $DeploymentType -eq 'Cloud'
                }
            }

            It "routes byObject updates to the v2 pages route" {
                $page = [ConfluencePS.Page]::new()
                $page.ID = 99
                $page.Title = "Object title"
                $page.Body = "<p>Object body</p>"
                $page.Version = [ConfluencePS.Version]::new()
                $page.Version.Number = 1

                $null = Set-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -InputObject $page -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/pages/99"
                $script:lastRequestBody.version.number | Should -Be 2
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = Set-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -PageID 42 -Title "New title" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/42"
            }
        }
    }
}
