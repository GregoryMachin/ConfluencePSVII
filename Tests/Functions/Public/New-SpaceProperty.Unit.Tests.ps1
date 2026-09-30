#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "New-SpaceProperty" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri, [string]$Body)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                ConvertFrom-Json '{"id": "1000", "key": "my-app.settings", "value": {"enabled": true}}'
            }
        }

        It "routes to the dedicated v2 property collection route and sends key/value" {
            $result = New-SpaceProperty -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -Key "my-app.settings" -Value @{ enabled = $true } -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/spaces/98307/properties"
            $script:lastBody.key | Should -Be 'my-app.settings'
            $script:lastBody.value.enabled | Should -Be $true
            $result | Should -BeOfType [ConfluencePSVII.SpaceProperty]
        }

        It "rejects a key that looks like it contains a secret before sending a request" {
            { New-SpaceProperty -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -Key "apiToken" -Value "x" -Confirm:$false } | Should -Throw

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It
        }

        It "rejects a value containing a nested secret-looking key before sending a request" {
            { New-SpaceProperty -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -Key "config" -Value @{ password = "x" } -Confirm:$false } | Should -Throw

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It
        }

        It "does not call Invoke-Method when -WhatIf is set" {
            $null = New-SpaceProperty -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -Key "my-app.settings" -Value "x" -WhatIf

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It
        }
    }
}
