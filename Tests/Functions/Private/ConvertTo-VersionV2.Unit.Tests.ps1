#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "ConvertTo-VersionV2" -Tag 'Unit' {
        BeforeAll {
            $script:fullJson = @'
{
    "authorId": "712020:aaaa-bbbb-cccc",
    "createdAt": "2023-05-24T15:11:22.331Z",
    "number": 3,
    "message": "Updated the intro",
    "minorEdit": true,
    "unexpectedField": "ignored"
}
'@
            $script:fullObject = ConvertFrom-Json -InputObject $fullJson
        }

        Context "Object conversion" {
            It "creates a ConfluencePSVII.Version object" {
                $result = ConvertTo-VersionV2 -InputObject $fullObject

                $result | Should -BeOfType [ConfluencePSVII.Version]
            }

            It "does not throw on an unrecognized field" {
                { ConvertTo-VersionV2 -InputObject $fullObject } | Should -Not -Throw
            }
        }

        Context "Property mapping" {
            BeforeAll {
                $script:result = ConvertTo-VersionV2 -InputObject $fullObject
            }

            It "maps authorId to By.UserKey" {
                $result.By.UserKey | Should -Be '712020:aaaa-bbbb-cccc'
            }

            It "parses createdAt as a DateTime" {
                $result.When | Should -BeOfType [DateTime]
                # Compare the UTC instant rather than the raw value: PowerShell 7's
                # ConvertFrom-Json auto-detects ISO 8601 strings and returns a Kind=Utc
                # DateTime directly, while re-parsing the same literal from a plain string
                # in this test localizes it, unlike ConvertFrom-Json's own detection.
                $result.When.ToUniversalTime() | Should -Be ([DateTime]'2023-05-24T15:11:22.331Z').ToUniversalTime()
            }

            It "maps number and message directly" {
                $result.Number | Should -Be 3
                $result.Message | Should -Be 'Updated the intro'
            }

            It "maps minorEdit to MinorEdit" {
                $result.MinorEdit | Should -BeTrue
            }

            It "leaves FriendlyWhen unset, since v2 has no equivalent field" {
                $result.FriendlyWhen | Should -BeNullOrEmpty
            }
        }

        Context "Missing optional fields" {
            It "handles a version with no authorId or message" {
                $sparse = ConvertFrom-Json -InputObject '{"number": 1, "createdAt": "2023-01-01T00:00:00.000Z"}'

                $result = ConvertTo-VersionV2 -InputObject $sparse

                $result.By | Should -BeNullOrEmpty
                $result.Message | Should -BeNullOrEmpty
                $result.MinorEdit | Should -BeFalse
            }
        }

        Context "Pipeline support" {
            It "accepts input from the pipeline" {
                $result = $fullObject | ConvertTo-VersionV2

                $result | Should -Not -BeNullOrEmpty
            }

            It "handles array input" {
                $result = @($fullObject, $fullObject) | ConvertTo-VersionV2

                @($result).Count | Should -Be 2
            }

            It "ignores a null item in the pipeline" {
                { $null | ConvertTo-VersionV2 } | Should -Not -Throw
            }
        }
    }
}
