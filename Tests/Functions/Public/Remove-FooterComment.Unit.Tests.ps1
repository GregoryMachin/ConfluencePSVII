#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Remove-FooterComment" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePS {
                param([Uri]$Uri)
                $script:lastUri = $Uri.AbsoluteUri
            }
        }

        It "uses the v1 content route by default" {
            $null = Remove-FooterComment -ApiUri "https://example.com/wiki/rest/api" -CommentID 327680 -Confirm:$false

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/327680"
        }

        It "routes to the v2 footer-comments route when -BaseUri and -DeploymentType Cloud are supplied" {
            $null = Remove-FooterComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -CommentID 327680 -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/footer-comments/327680"
        }

        It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
            $null = Remove-FooterComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -CommentID 327680 -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/327680"
        }

        It "does not call Invoke-Method when -WhatIf is set" {
            $null = Remove-FooterComment -ApiUri "https://example.com/wiki/rest/api" -CommentID 327680 -WhatIf

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 0 -Scope It
        }
    }
}
