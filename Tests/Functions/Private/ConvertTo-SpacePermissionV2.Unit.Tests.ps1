#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "ConvertTo-SpacePermissionV2" -Tag 'Unit' {
        BeforeAll {
            $script:fullJson = @'
{
    "id": "2000",
    "principal": { "type": "user", "id": "712020:aaaa" },
    "operation": { "key": "read", "targetType": "space" }
}
'@
            $script:fullObject = ConvertFrom-Json -InputObject $fullJson
        }

        It "creates a ConfluencePSVII.SpacePermission object" {
            $result = ConvertTo-SpacePermissionV2 -InputObject $fullObject -SpaceID 98307

            $result | Should -BeOfType [ConfluencePSVII.SpacePermission]
        }

        It "casts the numeric-string id to UInt64" {
            $result = ConvertTo-SpacePermissionV2 -InputObject $fullObject -SpaceID 98307

            $result.ID | Should -Be 2000
            $result.ID | Should -BeOfType [UInt64]
        }

        It "sets SpaceID from the caller-supplied parameter" {
            $result = ConvertTo-SpacePermissionV2 -InputObject $fullObject -SpaceID 98307

            $result.SpaceID | Should -Be 98307
        }

        It "maps the principal type and id" {
            $result = ConvertTo-SpacePermissionV2 -InputObject $fullObject -SpaceID 98307

            $result.PrincipalType | Should -Be 'user'
            $result.PrincipalID | Should -Be '712020:aaaa'
        }

        It "maps the operation key and target type" {
            $result = ConvertTo-SpacePermissionV2 -InputObject $fullObject -SpaceID 98307

            $result.OperationKey | Should -Be 'read'
            $result.OperationTargetType | Should -Be 'space'
        }

        It "handles a group principal" {
            $json = ConvertFrom-Json -InputObject '{"id": "1", "principal": {"type": "group", "id": "confluence-users"}, "operation": {"key": "read", "targetType": "space"}}'

            (ConvertTo-SpacePermissionV2 -InputObject $json).PrincipalType | Should -Be 'group'
        }

        It "does not throw on null input" {
            { $null | ConvertTo-SpacePermissionV2 } | Should -Not -Throw
        }

        It "handles array input" {
            $result = @($fullObject, $fullObject) | ConvertTo-SpacePermissionV2 -SpaceID 98307

            @($result).Count | Should -Be 2
        }
    }
}
