#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Get-SpaceProperty" -Tag 'Unit' {
        BeforeEach {
            $script:lastUri = $null
            $script:lastGetParameters = $null

            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri, [hashtable]$GetParameters)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastGetParameters = $GetParameters
                ConvertFrom-Json '{"id": "1000", "key": "my-app.settings", "value": {"enabled": true}}'
            }
        }

        It "routes a byId request to the dedicated v2 property route" {
            $result = Get-SpaceProperty -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -PropertyID 1000

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/spaces/98307/properties/1000"
            $result | Should -BeOfType [ConfluencePSVII.SpaceProperty]
        }

        It "routes a byKey request to the collection with no filter by default" {
            $result = Get-SpaceProperty -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/spaces/98307/properties"
            $result | Should -BeOfType [ConfluencePSVII.SpaceProperty]
        }

        It "forwards -Key as a collection filter" {
            $null = Get-SpaceProperty -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -Key "my-app.settings"

            $script:lastGetParameters['key'] | Should -Be 'my-app.settings'
        }

        It "throws when -BaseUri is not an HTTPS URI, since space properties have no v1/Data Center equivalent" {
            { Get-SpaceProperty -ApiUri "http://dc.example.com/rest/api" -BaseUri "http://dc.example.com" -SpaceID 98307 -PropertyID 1000 } | Should -Throw
        }
    }
}
