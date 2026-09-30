#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "ConvertTo-SpaceRoleAssignmentV2" -Tag 'Unit' {
        BeforeAll {
            $script:fullJson = @'
{
    "principal": { "type": "user", "id": "712020:aaaa" },
    "role": { "id": "role-admin", "name": "Admin" }
}
'@
            $script:fullObject = ConvertFrom-Json -InputObject $fullJson
        }

        It "creates a ConfluencePSVII.SpaceRoleAssignment object" {
            $result = ConvertTo-SpaceRoleAssignmentV2 -InputObject $fullObject -SpaceID 98307

            $result | Should -BeOfType [ConfluencePSVII.SpaceRoleAssignment]
        }

        It "sets SpaceID from the caller-supplied parameter" {
            $result = ConvertTo-SpaceRoleAssignmentV2 -InputObject $fullObject -SpaceID 98307

            $result.SpaceID | Should -Be 98307
        }

        It "maps the principal type and id" {
            $result = ConvertTo-SpaceRoleAssignmentV2 -InputObject $fullObject -SpaceID 98307

            $result.PrincipalType | Should -Be 'user'
            $result.PrincipalID | Should -Be '712020:aaaa'
        }

        It "maps the role id and name" {
            $result = ConvertTo-SpaceRoleAssignmentV2 -InputObject $fullObject -SpaceID 98307

            $result.RoleID | Should -Be 'role-admin'
            $result.RoleName | Should -Be 'Admin'
        }

        It "handles a group principal" {
            $json = ConvertFrom-Json -InputObject '{"principal": {"type": "group", "id": "confluence-users"}, "role": {"id": "role-viewer", "name": "Viewer"}}'

            (ConvertTo-SpaceRoleAssignmentV2 -InputObject $json).PrincipalType | Should -Be 'group'
        }

        It "does not throw on null input" {
            { $null | ConvertTo-SpaceRoleAssignmentV2 } | Should -Not -Throw
        }

        It "handles array input" {
            $result = @($fullObject, $fullObject) | ConvertTo-SpaceRoleAssignmentV2 -SpaceID 98307

            @($result).Count | Should -Be 2
        }
    }
}
