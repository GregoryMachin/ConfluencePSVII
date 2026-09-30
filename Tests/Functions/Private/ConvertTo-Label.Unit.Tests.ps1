#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "ConvertTo-Label" -Tag 'Unit' {
        Context "v1 shape (GET /content/{id}/label)" {
            BeforeAll {
                $json = '{"id": "123", "name": "how-to", "prefix": "global"}'
                $script:result = ConvertTo-Label -InputObject (ConvertFrom-Json -InputObject $json)
            }

            It "creates a ConfluencePSVII.Label object" {
                $script:result | Should -BeOfType [ConfluencePSVII.Label]
            }

            It "maps id, name, and prefix" {
                $script:result.ID | Should -Be 123
                $script:result.Name | Should -Be 'how-to'
                $script:result.Prefix | Should -Be 'global'
            }
        }

        Context "Cloud v2 shape (GET /pages/{id}/labels)" {
            BeforeAll {
                # Confluence Cloud v2 label items use the same {id, name, prefix} shape as v1;
                # no dedicated v2 adapter is needed, but this fixture proves it explicitly
                # rather than relying on the v1 shape alone (see docs/api-contract-inventory.md).
                $json = '{"id": "123", "name": "how-to", "prefix": "global", "unexpectedField": "ignored"}'
                $script:result = ConvertTo-Label -InputObject (ConvertFrom-Json -InputObject $json)
            }

            It "creates a ConfluencePSVII.Label object from the v2 shape too" {
                $script:result | Should -BeOfType [ConfluencePSVII.Label]
            }

            It "maps id, name, and prefix" {
                $script:result.ID | Should -Be 123
                $script:result.Name | Should -Be 'how-to'
                $script:result.Prefix | Should -Be 'global'
            }

            It "does not throw on an unrecognized field" {
                { ConvertTo-Label -InputObject (ConvertFrom-Json -InputObject $json) } | Should -Not -Throw
            }
        }

        Context "Missing optional fields" {
            It "handles a label with only a name" {
                $result = ConvertTo-Label -InputObject (ConvertFrom-Json -InputObject '{"name": "how-to"}')

                $result.Name | Should -Be 'how-to'
                $result.ID | Should -Be 0
                $result.Prefix | Should -BeNullOrEmpty
            }
        }

        Context "Pipeline support" {
            It "accepts input from the pipeline and handles arrays" {
                $one = ConvertFrom-Json -InputObject '{"id": "1", "name": "a"}'
                $two = ConvertFrom-Json -InputObject '{"id": "2", "name": "b"}'

                $result = @($one, $two) | ConvertTo-Label

                @($result).Count | Should -Be 2
            }
        }
    }
}
