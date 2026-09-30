#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "ConvertTo-SpacePropertyV2" -Tag 'Unit' {
        BeforeAll {
            $script:fullJson = @'
{
    "id": "1000",
    "key": "my-app.settings",
    "value": { "enabled": true, "count": 3 },
    "version": {
        "authorId": "712020:aaaa",
        "createdAt": "2023-05-24T15:11:22.331Z",
        "number": 1,
        "message": "",
        "minorEdit": false
    }
}
'@
            $script:fullObject = ConvertFrom-Json -InputObject $fullJson
        }

        It "creates a ConfluencePSVII.SpaceProperty object" {
            $result = ConvertTo-SpacePropertyV2 -InputObject $fullObject -SpaceID 98307

            $result | Should -BeOfType [ConfluencePSVII.SpaceProperty]
        }

        It "casts the numeric-string id to UInt64" {
            $result = ConvertTo-SpacePropertyV2 -InputObject $fullObject -SpaceID 98307

            $result.ID | Should -Be 1000
            $result.ID | Should -BeOfType [UInt64]
        }

        It "sets SpaceID from the caller-supplied parameter, since the response does not echo it" {
            $result = ConvertTo-SpacePropertyV2 -InputObject $fullObject -SpaceID 98307

            $result.SpaceID | Should -Be 98307
        }

        It "maps key directly" {
            $result = ConvertTo-SpacePropertyV2 -InputObject $fullObject -SpaceID 98307

            $result.Key | Should -Be 'my-app.settings'
        }

        It "passes the value object through as-is" {
            $result = ConvertTo-SpacePropertyV2 -InputObject $fullObject -SpaceID 98307

            $result.Value.enabled | Should -Be $true
            $result.Value.count | Should -Be 3
        }

        It "converts the nested version object" {
            $result = ConvertTo-SpacePropertyV2 -InputObject $fullObject -SpaceID 98307

            $result.Version.Number | Should -Be 1
        }

        It "does not throw on null input" {
            { $null | ConvertTo-SpacePropertyV2 } | Should -Not -Throw
        }

        It "handles array input" {
            $result = @($fullObject, $fullObject) | ConvertTo-SpacePropertyV2 -SpaceID 98307

            @($result).Count | Should -Be 2
        }
    }
}
