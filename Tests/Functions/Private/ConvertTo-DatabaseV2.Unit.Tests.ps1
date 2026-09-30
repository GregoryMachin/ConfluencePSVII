#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "ConvertTo-DatabaseV2" -Tag 'Unit' {
        BeforeAll {
            $script:fullJson = @'
{
    "id": "393216",
    "status": "current",
    "title": "Example Database",
    "spaceId": "98307",
    "parentId": "196608",
    "authorId": "712020:aaaa",
    "createdAt": "2023-05-24T15:11:22.331Z",
    "version": {
        "authorId": "712020:aaaa",
        "createdAt": "2023-05-24T15:11:22.331Z",
        "number": 1,
        "message": "",
        "minorEdit": false
    },
    "_links": {
        "webui": "/spaces/TEST/database/393216/Example+Database"
    },
    "unexpectedField": "ignored"
}
'@
            $script:fullObject = ConvertFrom-Json -InputObject $fullJson
            $script:baseUri = [Uri]'https://example.atlassian.net/wiki'
        }

        Context "Object conversion" {
            It "creates a ConfluencePSVII.Database object" {
                $result = ConvertTo-DatabaseV2 -InputObject $fullObject -BaseUri $baseUri

                $result | Should -BeOfType [ConfluencePSVII.Database]
            }

            It "does not throw on an unrecognized field" {
                { ConvertTo-DatabaseV2 -InputObject $fullObject } | Should -Not -Throw
            }
        }

        Context "Property mapping" {
            BeforeAll {
                $script:result = ConvertTo-DatabaseV2 -InputObject $fullObject -BaseUri $baseUri
            }

            It "casts the numeric-string id to UInt64" {
                $result.ID | Should -Be 393216
                $result.ID | Should -BeOfType [UInt64]
            }

            It "maps status and title directly" {
                $result.Status | Should -Be 'current'
                $result.Title | Should -Be 'Example Database'
            }

            It "populates Space with only the numeric ID" {
                $result.Space | Should -Not -BeNullOrEmpty
                $result.Space.Id | Should -Be 98307
            }

            It "reads parentId into ParentID" {
                $result.ParentID | Should -Be 196608
            }

            It "converts the nested version object" {
                $result.Version | Should -Not -BeNullOrEmpty
                $result.Version.Number | Should -Be 1
            }

            It "builds URL from BaseUri, since v2 has no _links.base" {
                $result.URL | Should -Be 'https://example.atlassian.net/wiki/spaces/TEST/database/393216/Example+Database'
            }
        }

        Context "Missing optional fields" {
            It "handles a minimal database with only an id" {
                $json = ConvertFrom-Json -InputObject '{"id": "1"}'

                $result = ConvertTo-DatabaseV2 -InputObject $json

                $result.ID | Should -Be 1
                $result.Space | Should -BeNullOrEmpty
                $result.Version | Should -BeNullOrEmpty
                $result.URL | Should -BeNullOrEmpty
            }
        }

        Context "Pipeline support" {
            It "accepts input from the pipeline" {
                $result = $fullObject | ConvertTo-DatabaseV2

                $result | Should -Not -BeNullOrEmpty
            }

            It "handles array input" {
                $result = @($fullObject, $fullObject) | ConvertTo-DatabaseV2

                @($result).Count | Should -Be 2
            }
        }
    }
}
