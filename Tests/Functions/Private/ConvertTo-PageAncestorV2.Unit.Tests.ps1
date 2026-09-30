#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "ConvertTo-PageAncestorV2" -Tag 'Unit' {
        It "creates a ConfluencePSVII.Page object with only Id, Status, and Title" {
            $json = ConvertFrom-Json -InputObject '{"id": "163840", "status": "current", "title": "Parent Page", "spaceId": "98307"}'

            $result = ConvertTo-PageAncestorV2 -InputObject $json

            $result | Should -BeOfType [ConfluencePSVII.Page]
            $result.ID | Should -Be 163840
            $result.ID | Should -BeOfType [UInt64]
            $result.Status | Should -Be 'current'
            $result.Title | Should -Be 'Parent Page'
            $result.Space | Should -BeNullOrEmpty
            $result.Body | Should -BeNullOrEmpty
        }

        It "handles array input" {
            $json = @(
                (ConvertFrom-Json -InputObject '{"id": "1", "title": "Root"}'),
                (ConvertFrom-Json -InputObject '{"id": "2", "title": "Middle"}')
            )

            $result = @($json | ConvertTo-PageAncestorV2)

            $result.Count | Should -Be 2
            $result[0].Title | Should -Be 'Root'
            $result[1].Title | Should -Be 'Middle'
        }

        It "does not throw on null input" {
            { $null | ConvertTo-PageAncestorV2 } | Should -Not -Throw
        }
    }
}
