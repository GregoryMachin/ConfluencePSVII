#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Get-SpacePermission" -Tag 'Unit' {
        BeforeEach {
            $script:lastUri = $null

            Mock Invoke-Method -ModuleName ConfluencePS {
                param([Uri]$Uri)
                $script:lastUri = $Uri.AbsoluteUri
                ConvertFrom-Json '{"id": "2000", "principal": {"type": "user", "id": "712020:aaaa"}, "operation": {"key": "read", "targetType": "space"}}'
            }
        }

        It "routes to the dedicated v2 permissions route" {
            $result = Get-SpacePermission -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/spaces/98307/permissions"
            $result | Should -BeOfType [ConfluencePS.SpacePermission]
        }

        It "sets SpaceID on the returned objects" {
            $result = Get-SpacePermission -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307

            $result.SpaceID | Should -Be 98307
        }

        It "throws when -BaseUri is not an HTTPS URI, since space permissions have no v1/Data Center equivalent" {
            { Get-SpacePermission -ApiUri "http://dc.example.com/rest/api" -BaseUri "http://dc.example.com" -SpaceID 98307 } | Should -Throw
        }
    }
}
