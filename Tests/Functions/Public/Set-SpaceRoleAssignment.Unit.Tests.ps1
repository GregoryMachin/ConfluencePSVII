#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Set-SpaceRoleAssignment" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri, [string]$Body)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                ConvertFrom-Json '{"principal": {"type": "user", "id": "712020:aaaa"}, "role": {"id": "role-admin", "name": "Admin"}}'
            }
        }

        It "routes to the dedicated v2 role-assignments route and sends the change" {
            $result = Set-SpaceRoleAssignment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -PrincipalType user -PrincipalID "712020:aaaa" -RoleID "role-admin" -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/spaces/98307/role-assignments"
            $script:lastBody[0].principalId | Should -Be '712020:aaaa'
            $script:lastBody[0].principalType | Should -Be 'user'
            $script:lastBody[0].roleId | Should -Be 'role-admin'
            $result | Should -BeOfType [ConfluencePSVII.SpaceRoleAssignment]
        }

        It "supports a group principal" {
            $null = Set-SpaceRoleAssignment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -PrincipalType group -PrincipalID "confluence-users" -RoleID "role-viewer" -Confirm:$false

            $script:lastBody[0].principalType | Should -Be 'group'
        }

        It "does not call Invoke-Method when -WhatIf is set" {
            $null = Set-SpaceRoleAssignment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceID 98307 -PrincipalType user -PrincipalID "712020:aaaa" -RoleID "role-admin" -WhatIf

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It
        }

        It "throws when -BaseUri is not an HTTPS URI, since role assignments have no v1/Data Center equivalent" {
            { Set-SpaceRoleAssignment -ApiUri "http://dc.example.com/rest/api" -BaseUri "http://dc.example.com" -SpaceID 98307 -PrincipalType user -PrincipalID "712020:aaaa" -RoleID "role-admin" -Confirm:$false } | Should -Throw
        }
    }
}
