#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "ConvertTo-CommentV2" -Tag 'Unit' {
        BeforeAll {
            $script:fullJson = @'
{
    "id": "327680",
    "status": "current",
    "pageId": "196608",
    "parentCommentId": "327679",
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
            "value": "<p>Nice work!</p>"
        }
    },
    "_links": {
        "webui": "/spaces/TEST/pages/196608/Example+Page?focusedCommentId=327680"
    },
    "unexpectedField": "ignored"
}
'@
            $script:fullObject = ConvertFrom-Json -InputObject $fullJson
            $script:baseUri = [Uri]'https://example.atlassian.net/wiki'
        }

        Context "Object conversion" {
            It "creates a ConfluencePSVII.Comment object" {
                $result = ConvertTo-CommentV2 -InputObject $fullObject -Type footer -BaseUri $baseUri

                $result | Should -BeOfType [ConfluencePSVII.Comment]
            }

            It "does not throw on an unrecognized field" {
                { ConvertTo-CommentV2 -InputObject $fullObject -Type footer } | Should -Not -Throw
            }
        }

        Context "Property mapping" {
            BeforeAll {
                $script:result = ConvertTo-CommentV2 -InputObject $fullObject -Type footer -BaseUri $baseUri
            }

            It "casts the numeric-string id to UInt64" {
                $result.ID | Should -Be 327680
                $result.ID | Should -BeOfType [UInt64]
            }

            It "maps status directly" {
                $result.Status | Should -Be 'current'
            }

            It "reads pageId into PageID" {
                $result.PageID | Should -Be 196608
            }

            It "reads parentCommentId into ParentID" {
                $result.ParentID | Should -Be 327679
            }

            It "converts the nested version object" {
                $result.Version | Should -Not -BeNullOrEmpty
                $result.Version.By.UserKey | Should -Be '712020:aaaa'
                $result.Version.Number | Should -Be 1
            }

            It "reads the storage body representation" {
                $result.Body | Should -Be '<p>Nice work!</p>'
            }

            It "records the caller-supplied Type" {
                $result.Type | Should -Be 'footer'
            }

            It "builds URL from BaseUri, since v2 has no _links.base" {
                $result.URL | Should -Be 'https://example.atlassian.net/wiki/spaces/TEST/pages/196608/Example+Page?focusedCommentId=327680'
            }
        }

        Context "Blog post container" {
            It "reads blogPostId into PageID when pageId is absent" {
                $json = ConvertFrom-Json -InputObject '{"id": "1", "blogPostId": "262144"}'

                (ConvertTo-CommentV2 -InputObject $json -Type footer).PageID | Should -Be 262144
            }
        }

        Context "Body format fallback" {
            It "falls back to the view representation when storage is absent" {
                $json = ConvertFrom-Json -InputObject '{"id": "1", "body": {"view": {"value": "<p>View body</p>"}}}'

                (ConvertTo-CommentV2 -InputObject $json -Type footer).Body | Should -Be '<p>View body</p>'
            }

            It "leaves Body unset when no known representation is present" {
                $json = ConvertFrom-Json -InputObject '{"id": "1"}'

                (ConvertTo-CommentV2 -InputObject $json -Type footer).Body | Should -BeNullOrEmpty
            }
        }

        Context "Missing optional fields" {
            It "handles a minimal comment with only an id" {
                $json = ConvertFrom-Json -InputObject '{"id": "1"}'

                $result = ConvertTo-CommentV2 -InputObject $json -Type inline

                $result.ID | Should -Be 1
                $result.ParentID | Should -Be 0
                $result.Version | Should -BeNullOrEmpty
                $result.URL | Should -BeNullOrEmpty
                $result.Type | Should -Be 'inline'
            }
        }

        Context "Pipeline support" {
            It "accepts input from the pipeline" {
                $result = $fullObject | ConvertTo-CommentV2 -Type footer

                $result | Should -Not -BeNullOrEmpty
            }

            It "handles array input" {
                $result = @($fullObject, $fullObject) | ConvertTo-CommentV2 -Type footer

                @($result).Count | Should -Be 2
            }
        }
    }
}
