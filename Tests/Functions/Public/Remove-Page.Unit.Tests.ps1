#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Remove-Page" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri)
                $script:lastUri = $Uri.AbsoluteUri
            }
        }

        It "uses the v1 content route by default" {
            $null = Remove-Page -ApiUri "https://example.com/wiki/rest/api" -PageID 100 -Confirm:$false

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/100"
        }

        It "routes to the v2 pages route when -BaseUri and -DeploymentType Cloud are supplied" {
            $null = Remove-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 100 -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/pages/100"
        }

        It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
            $null = Remove-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -PageID 100 -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/100"
        }

        It "uses the v1 route for Data Center regardless of -BaseUri" {
            $null = Remove-Page -ApiUri "https://dc.example.com/rest/api" -BaseUri "https://dc.example.com" -DeploymentType DataCenter -PageID 100 -Confirm:$false

            $script:lastUri | Should -Be "https://dc.example.com/rest/api/content/100"
        }

        It "does not call Invoke-Method when -WhatIf is set" {
            $null = Remove-Page -ApiUri "https://example.com/wiki/rest/api" -PageID 100 -WhatIf

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It
        }
    }
}
