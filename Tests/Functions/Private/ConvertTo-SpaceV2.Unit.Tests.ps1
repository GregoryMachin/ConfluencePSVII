#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "ConvertTo-SpaceV2" -Tag 'Unit' {
        BeforeAll {
            $script:fullJson = @'
{
    "id": "98307",
    "key": "TEST",
    "name": "Test Space",
    "type": "global",
    "status": "current",
    "authorId": "712020:aaaa",
    "homepageId": "196608",
    "description": {
        "plain": {
            "value": "A test space",
            "representation": "plain"
        }
    },
    "icon": {
        "path": "/images/icons/space.png"
    },
    "unexpectedField": "ignored"
}
'@
            $script:fullObject = ConvertFrom-Json -InputObject $fullJson
        }

        Context "Object conversion" {
            It "creates a ConfluencePS.Space object" {
                $result = ConvertTo-SpaceV2 -InputObject $fullObject

                $result | Should -BeOfType [ConfluencePS.Space]
            }

            It "does not throw on an unrecognized field" {
                { ConvertTo-SpaceV2 -InputObject $fullObject } | Should -Not -Throw
            }
        }

        Context "Property mapping" {
            BeforeAll {
                $script:result = ConvertTo-SpaceV2 -InputObject $fullObject
            }

            It "casts the numeric-string id to UInt64" {
                $result.Id | Should -Be 98307
                $result.Id | Should -BeOfType [UInt64]
            }

            It "maps key, name, and type directly" {
                $result.Key | Should -Be 'TEST'
                $result.Name | Should -Be 'Test Space'
                $result.Type | Should -Be 'global'
            }

            It "reads the plain-text description" {
                $result.Description | Should -Be 'A test space'
            }

            It "converts the icon" {
                $result.Icon.Path | Should -Be '/images/icons/space.png'
            }

            It "populates Homepage with only the numeric ID, since v2 does not embed the full page" {
                $result.Homepage | Should -Not -BeNullOrEmpty
                $result.Homepage.ID | Should -Be 196608
                $result.Homepage.Title | Should -BeNullOrEmpty
            }
        }

        Context "Missing optional fields" {
            It "handles a minimal space with only key fields" {
                $json = ConvertFrom-Json -InputObject '{"id": "1", "key": "MIN", "name": "Minimal"}'

                $result = ConvertTo-SpaceV2 -InputObject $json

                $result.Description | Should -BeNullOrEmpty
                $result.Icon | Should -BeNullOrEmpty
                $result.Homepage | Should -BeNullOrEmpty
            }
        }

        Context "Pipeline support" {
            It "accepts input from the pipeline" {
                $result = $fullObject | ConvertTo-SpaceV2

                $result | Should -Not -BeNullOrEmpty
            }

            It "handles array input" {
                $result = @($fullObject, $fullObject) | ConvertTo-SpaceV2

                @($result).Count | Should -Be 2
            }
        }
    }
}
