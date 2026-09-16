#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Remove-BlogPost" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePS {
                param([Uri]$Uri)
                $script:lastUri = $Uri.AbsoluteUri
            }
        }

        It "uses the v1 content route by default" {
            $null = Remove-BlogPost -ApiUri "https://example.com/wiki/rest/api" -BlogPostID 262144 -Confirm:$false

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/262144"
        }

        It "routes to the v2 blogposts route when -BaseUri and -DeploymentType Cloud are supplied" {
            $null = Remove-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -BlogPostID 262144 -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/blogposts/262144"
        }

        It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
            $null = Remove-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -BlogPostID 262144 -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/262144"
        }

        It "uses the v1 route for Data Center regardless of -BaseUri" {
            $null = Remove-BlogPost -ApiUri "https://dc.example.com/rest/api" -BaseUri "https://dc.example.com" -DeploymentType DataCenter -BlogPostID 262144 -Confirm:$false

            $script:lastUri | Should -Be "https://dc.example.com/rest/api/content/262144"
        }

        It "does not call Invoke-Method when -WhatIf is set" {
            $null = Remove-BlogPost -ApiUri "https://example.com/wiki/rest/api" -BlogPostID 262144 -WhatIf

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 0 -Scope It
        }
    }
}
