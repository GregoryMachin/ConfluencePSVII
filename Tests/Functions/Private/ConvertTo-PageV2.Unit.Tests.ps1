#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "ConvertTo-PageV2" -Tag 'Unit' {
        BeforeAll {
            $script:fullJson = @'
{
    "id": "196608",
    "status": "current",
    "title": "Example Page",
    "spaceId": "98307",
    "parentId": "163840",
    "authorId": "712020:aaaa",
    "createdAt": "2023-05-24T15:11:22.331Z",
    "version": {
        "authorId": "712020:aaaa",
        "createdAt": "2023-05-24T15:11:22.331Z",
        "number": 1,
        "message": "",
        "minorEdit": false
    },
    "body": {
        "storage": {
            "representation": "storage",
            "value": "<p>Content</p>"
        }
    },
    "_links": {
        "webui": "/spaces/TEST/pages/196608/Example+Page",
        "tinyui": "/x/AoQI"
    },
    "unexpectedField": "ignored"
}
'@
            $script:fullObject = ConvertFrom-Json -InputObject $fullJson
            $script:baseUri = [Uri]'https://example.atlassian.net/wiki'
        }

        Context "Object conversion" {
            It "creates a ConfluencePS.Page object" {
                $result = ConvertTo-PageV2 -InputObject $fullObject -BaseUri $baseUri

                $result | Should -BeOfType [ConfluencePS.Page]
            }

            It "does not throw on an unrecognized field" {
                { ConvertTo-PageV2 -InputObject $fullObject } | Should -Not -Throw
            }
        }

        Context "Property mapping" {
            BeforeAll {
                $script:result = ConvertTo-PageV2 -InputObject $fullObject -BaseUri $baseUri
            }

            It "casts the numeric-string id to UInt64" {
                $result.ID | Should -Be 196608
                $result.ID | Should -BeOfType [UInt64]
            }

            It "maps status and title directly" {
                $result.Status | Should -Be 'current'
                $result.Title | Should -Be 'Example Page'
            }

            It "populates Space with only the numeric ID, since v2 does not embed the full space" {
                $result.Space | Should -Not -BeNullOrEmpty
                $result.Space.Id | Should -Be 98307
                $result.Space.Key | Should -BeNullOrEmpty
            }

            It "converts the nested version object" {
                $result.Version | Should -Not -BeNullOrEmpty
                $result.Version.By.UserKey | Should -Be '712020:aaaa'
                $result.Version.Number | Should -Be 1
            }

            It "reads the storage body representation" {
                $result.Body | Should -Be '<p>Content</p>'
            }

            It "leaves Ancestors unset, since v2 requires a separate request for them" {
                $result.Ancestors | Should -BeNullOrEmpty
            }

            It "builds URL and ShortURL from BaseUri, since v2 has no _links.base" {
                $result.URL | Should -Be 'https://example.atlassian.net/wiki/spaces/TEST/pages/196608/Example+Page'
                $result.ShortURL | Should -Be 'https://example.atlassian.net/wiki/x/AoQI'
            }
        }

        Context "Body format fallback" {
            It "falls back to the view representation when storage is absent" {
                $json = ConvertFrom-Json -InputObject '{"id": "1", "body": {"view": {"value": "<p>View body</p>"}}}'

                (ConvertTo-PageV2 -InputObject $json).Body | Should -Be '<p>View body</p>'
            }

            It "falls back to atlas_doc_format when neither storage nor view is present" {
                $json = ConvertFrom-Json -InputObject '{"id": "1", "body": {"atlas_doc_format": {"value": "{\"type\":\"doc\"}"}}}'

                (ConvertTo-PageV2 -InputObject $json).Body | Should -Be '{"type":"doc"}'
            }

            It "leaves Body unset when no known representation is present" {
                $json = ConvertFrom-Json -InputObject '{"id": "1"}'

                (ConvertTo-PageV2 -InputObject $json).Body | Should -BeNullOrEmpty
            }
        }

        Context "Missing optional fields" {
            It "handles a minimal page with only an id" {
                $json = ConvertFrom-Json -InputObject '{"id": "1"}'

                $result = ConvertTo-PageV2 -InputObject $json

                $result.ID | Should -Be 1
                $result.Space | Should -BeNullOrEmpty
                $result.Version | Should -BeNullOrEmpty
                $result.URL | Should -BeNullOrEmpty
                $result.ShortURL | Should -BeNullOrEmpty
            }

            It "leaves URL and ShortURL unset when neither _links.base nor -BaseUri is available" {
                $json = ConvertFrom-Json -InputObject '{"id": "1", "_links": {"webui": "/spaces/TEST/pages/1"}}'

                $result = ConvertTo-PageV2 -InputObject $json

                $result.URL | Should -BeNullOrEmpty
            }
        }

        Context "Links" {
            It "prefers a response-supplied _links.base over -BaseUri" {
                $json = ConvertFrom-Json -InputObject '{"id": "1", "_links": {"base": "https://from-response.atlassian.net", "webui": "/x/1"}}'

                $result = ConvertTo-PageV2 -InputObject $json -BaseUri ([Uri]'https://from-parameter.atlassian.net')

                $result.URL | Should -Be 'https://from-response.atlassian.net/x/1'
            }
        }

        Context "Pipeline support" {
            It "accepts input from the pipeline" {
                $result = $fullObject | ConvertTo-PageV2

                $result | Should -Not -BeNullOrEmpty
            }

            It "handles array input" {
                $result = @($fullObject, $fullObject) | ConvertTo-PageV2

                @($result).Count | Should -Be 2
            }
        }
    }
}
