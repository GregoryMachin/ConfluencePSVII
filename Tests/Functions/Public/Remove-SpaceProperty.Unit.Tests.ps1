#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Remove-SpaceProperty" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePS {
                param([Uri]$Uri)
                $script:lastUri = $Uri.AbsoluteUri
            }
        }

        It "routes to the dedicated v2 property route" {
            $null = Remove-SpaceProperty -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -PropertyID 1000 -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/spaces/98307/properties/1000"
        }

        It "requests one deletion per PropertyID" {
            $null = Remove-SpaceProperty -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -PropertyID 1000, 1001 -Confirm:$false

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 2 -Scope It
        }

        It "throws when -BaseUri is not an HTTPS URI, since space properties have no v1/Data Center equivalent" {
            { Remove-SpaceProperty -ApiUri "http://dc.example.com/rest/api" -BaseUri "http://dc.example.com" -SpaceID 98307 -PropertyID 1000 -Confirm:$false } | Should -Throw
        }

        It "does not call Invoke-Method when -WhatIf is set" {
            $null = Remove-SpaceProperty -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -PropertyID 1000 -WhatIf

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 0 -Scope It
        }
    }
}
