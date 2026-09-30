#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Get-SpaceRoleAssignment" -Tag 'Unit' {
        BeforeEach {
            $script:lastUri = $null

            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri)
                $script:lastUri = $Uri.AbsoluteUri
                ConvertFrom-Json '{"principal": {"type": "user", "id": "712020:aaaa"}, "role": {"id": "role-admin", "name": "Admin"}}'
            }
        }

        It "routes to the dedicated v2 role-assignments route" {
            $result = Get-SpaceRoleAssignment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/spaces/98307/role-assignments"
            $result | Should -BeOfType [ConfluencePSVII.SpaceRoleAssignment]
        }

        It "sets SpaceID on the returned objects" {
            $result = Get-SpaceRoleAssignment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307

            $result.SpaceID | Should -Be 98307
        }

        It "throws when -BaseUri is not an HTTPS URI, since role assignments have no v1/Data Center equivalent" {
            { Get-SpaceRoleAssignment -ApiUri "http://dc.example.com/rest/api" -BaseUri "http://dc.example.com" -SpaceID 98307 } | Should -Throw
        }
    }
}
