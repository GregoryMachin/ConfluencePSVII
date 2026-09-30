#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "ConvertTo-AttachmentV2" -Tag 'Unit' {
        BeforeAll {
            $script:fullJson = @'
{
    "id": "att123456",
    "status": "current",
    "title": "diagram.png",
    "mediaType": "image/png",
    "comment": "Architecture diagram",
    "fileSize": 45231,
    "pageId": "196608",
    "downloadLink": "/download/attachments/196608/diagram.png?api=v2",
    "version": {
        "authorId": "712020:aaaa",
        "createdAt": "2023-05-24T15:11:22.331Z",
        "number": 1,
        "minorEdit": false
    },
    "unexpectedField": "ignored"
}
'@
            $script:fullObject = ConvertFrom-Json -InputObject $fullJson
            $script:baseUri = [Uri]'https://example.atlassian.net/wiki'
        }

        Context "Object conversion" {
            It "creates a ConfluencePSVII.Attachment object" {
                $result = ConvertTo-AttachmentV2 -InputObject $fullObject -BaseUri $baseUri

                $result | Should -BeOfType [ConfluencePSVII.Attachment]
            }

            It "does not throw on an unrecognized field" {
                { ConvertTo-AttachmentV2 -InputObject $fullObject } | Should -Not -Throw
            }
        }

        Context "Property mapping" {
            BeforeAll {
                $script:result = ConvertTo-AttachmentV2 -InputObject $fullObject -BaseUri $baseUri
            }

            It "strips the 'att' prefix and casts the id to UInt64" {
                $result.ID | Should -Be 123456
                $result.ID | Should -BeOfType [UInt64]
            }

            It "maps status, title, mediatype, filesize, and comment directly" {
                $result.Status | Should -Be 'current'
                $result.Title | Should -Be 'diagram.png'
                $result.MediaType | Should -Be 'image/png'
                $result.FileSize | Should -Be 45231
                $result.Comment | Should -Be 'Architecture diagram'
            }

            It "reads pageId directly, unlike the v1 adapter's _expandable.container parsing" {
                $result.PageID | Should -Be 196608
            }

            It "builds a sanitized filename from pageId and title" {
                $result.Filename | Should -Be '196608_diagram.png'
            }

            It "leaves SpaceKey unset, since v2 attachments do not carry it" {
                $result.SpaceKey | Should -BeNullOrEmpty
            }

            It "converts the nested version object" {
                $result.Version.By.UserKey | Should -Be '712020:aaaa'
            }

            It "builds the URL from -BaseUri and downloadLink, since v2 has no _links.base" {
                $result.URL | Should -Be 'https://example.atlassian.net/wiki/download/attachments/196608/diagram.png?api=v2'
            }
        }

        Context "Missing optional fields" {
            It "handles a minimal attachment with only id, title, and pageId" {
                $json = ConvertFrom-Json -InputObject '{"id": "att1", "title": "file.txt", "pageId": "1"}'

                $result = ConvertTo-AttachmentV2 -InputObject $json

                $result.ID | Should -Be 1
                $result.Comment | Should -BeNullOrEmpty
                $result.Version | Should -BeNullOrEmpty
                $result.URL | Should -BeNullOrEmpty
            }
        }

        Context "Pipeline support" {
            It "accepts input from the pipeline" {
                $result = $fullObject | ConvertTo-AttachmentV2

                $result | Should -Not -BeNullOrEmpty
            }

            It "handles array input" {
                $result = @($fullObject, $fullObject) | ConvertTo-AttachmentV2

                @($result).Count | Should -Be 2
            }
        }
    }
}
