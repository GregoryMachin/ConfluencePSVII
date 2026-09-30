#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Set-SpaceProperty" -Tag 'Unit' {
        BeforeEach {
            Mock Get-SpaceProperty -ModuleName ConfluencePSVII {
                [ConfluencePSVII.SpaceProperty]@{ ID = 1000; SpaceID = 98307; Key = 'my-app.settings'; Value = @{ enabled = $false }; Version = [ConfluencePSVII.Version]@{ Number = 1 } }
            }
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri, [string]$Body)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                ConvertFrom-Json '{"id": "1000", "key": "my-app.settings", "value": {"enabled": true}}'
            }
        }

        It "reads the original property and increments its version" {
            $result = Set-SpaceProperty -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -PropertyID 1000 -Value @{ enabled = $true } -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/spaces/98307/properties/1000"
            $script:lastBody.version.number | Should -Be 2
            $script:lastBody.value.enabled | Should -Be $true
            $result | Should -BeOfType [ConfluencePSVII.SpaceProperty]
        }

        It "preserves the original key" {
            $null = Set-SpaceProperty -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -PropertyID 1000 -Value @{ enabled = $true } -Confirm:$false

            $script:lastBody.key | Should -Be 'my-app.settings'
        }

        It "rejects a value containing a nested secret-looking key before sending a request" {
            { Set-SpaceProperty -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -PropertyID 1000 -Value @{ token = "x" } -Confirm:$false } | Should -Throw

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It
        }

        It "does not call Invoke-Method when -WhatIf is set" {
            $null = Set-SpaceProperty -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -PropertyID 1000 -Value @{ enabled = $true } -WhatIf

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It
        }
    }
}
