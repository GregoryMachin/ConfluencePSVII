#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Remove-Attachment" -Tag 'Unit' {
        BeforeEach {
            $script:attachment = [ConfluencePSVII.Attachment]::new()
            $script:attachment.ID = 55
            $script:attachment.PageID = 100

            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri)
                $script:lastUri = $Uri.AbsoluteUri
            }
        }

        It "uses the v1 generic content-delete route by default" {
            $null = Remove-Attachment -ApiUri "https://example.com/wiki/rest/api" -Attachment $script:attachment -Confirm:$false

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/55"
        }

        It "routes to the v2 attachment-delete route when -BaseUri and -DeploymentType Cloud are supplied" {
            $null = Remove-Attachment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -Attachment $script:attachment -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/attachments/55"
        }

        It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
            $null = Remove-Attachment -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -Attachment $script:attachment -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/55"
        }

        It "uses the v1 route for Data Center regardless of -BaseUri" {
            $null = Remove-Attachment -ApiUri "https://dc.example.com/rest/api" -BaseUri "https://dc.example.com" -DeploymentType DataCenter -Attachment $script:attachment -Confirm:$false

            $script:lastUri | Should -Be "https://dc.example.com/rest/api/content/55"
        }

        It "does not call Invoke-Method when -WhatIf is set" {
            $null = Remove-Attachment -ApiUri "https://example.com/wiki/rest/api" -Attachment $script:attachment -WhatIf

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It
        }
    }
}
