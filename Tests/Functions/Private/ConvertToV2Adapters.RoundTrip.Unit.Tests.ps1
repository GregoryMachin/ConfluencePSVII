#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "V1/v2 adapter round-trip compatibility" -Tag 'Unit' {
        <#
            These tests prove that feeding a v1-shaped fixture through the existing v1
            converter and a v2-shaped fixture through the new v2 adapter for the same
            resource yields the same output type with the same core properties populated,
            so a route migration (Task 44+) does not change what a script consuming
            ConfluencePS objects sees.
        #>

        Context "Page" {
            BeforeAll {
                $v1Json = @'
{
    "id": "196608",
    "status": "current",
    "title": "Example Page",
    "version": { "number": 2, "by": { "username": "jsmith", "displayName": "J Smith" } },
    "body": { "storage": { "value": "<p>Content</p>" } }
}
'@
                $v2Json = @'
{
    "id": "196608",
    "status": "current",
    "title": "Example Page",
    "version": { "number": 2, "authorId": "712020:aaaa" },
    "body": { "storage": { "value": "<p>Content</p>" } }
}
'@
                $script:v1Result = ConvertTo-Page -InputObject (ConvertFrom-Json -InputObject $v1Json)
                $script:v2Result = ConvertTo-PageV2 -InputObject (ConvertFrom-Json -InputObject $v2Json)
            }

            It "both produce a ConfluencePS.Page" {
                $v1Result | Should -BeOfType [ConfluencePS.Page]
                $v2Result | Should -BeOfType [ConfluencePS.Page]
            }

            It "both agree on ID, Status, Title, and Body" {
                $v1Result.ID | Should -Be $v2Result.ID
                $v1Result.Status | Should -Be $v2Result.Status
                $v1Result.Title | Should -Be $v2Result.Title
                $v1Result.Body | Should -Be $v2Result.Body
            }

            It "both populate Version.Number identically" {
                $v1Result.Version.Number | Should -Be $v2Result.Version.Number
            }
        }

        Context "Space" {
            BeforeAll {
                $v1Json = @'
{
    "id": 98307,
    "key": "TEST",
    "name": "Test Space",
    "type": "global",
    "description": { "plain": { "value": "A test space" } }
}
'@
                $v2Json = @'
{
    "id": "98307",
    "key": "TEST",
    "name": "Test Space",
    "type": "global",
    "description": { "plain": { "value": "A test space" } }
}
'@
                $script:v1Result = ConvertTo-Space -InputObject (ConvertFrom-Json -InputObject $v1Json)
                $script:v2Result = ConvertTo-SpaceV2 -InputObject (ConvertFrom-Json -InputObject $v2Json)
            }

            It "both produce a ConfluencePS.Space" {
                $v1Result | Should -BeOfType [ConfluencePS.Space]
                $v2Result | Should -BeOfType [ConfluencePS.Space]
            }

            It "both agree on Id, Key, Name, Type, and Description" {
                $v1Result.Id | Should -Be $v2Result.Id
                $v1Result.Key | Should -Be $v2Result.Key
                $v1Result.Name | Should -Be $v2Result.Name
                $v1Result.Type | Should -Be $v2Result.Type
                $v1Result.Description | Should -Be $v2Result.Description
            }
        }

        Context "Attachment" {
            BeforeAll {
                $v1Json = @'
{
    "id": "att123456",
    "status": "current",
    "title": "diagram.png",
    "extensions": { "mediaType": "image/png", "fileSize": "45231" },
    "container": { "id": "196608" }
}
'@
                $v2Json = @'
{
    "id": "att123456",
    "status": "current",
    "title": "diagram.png",
    "mediaType": "image/png",
    "fileSize": 45231,
    "pageId": "196608"
}
'@
                $script:v1Result = ConvertTo-Attachment -InputObject (ConvertFrom-Json -InputObject $v1Json)
                $script:v2Result = ConvertTo-AttachmentV2 -InputObject (ConvertFrom-Json -InputObject $v2Json)
            }

            It "both produce a ConfluencePS.Attachment" {
                $v1Result | Should -BeOfType [ConfluencePS.Attachment]
                $v2Result | Should -BeOfType [ConfluencePS.Attachment]
            }

            It "both agree on ID, Title, MediaType, FileSize, and PageID" {
                $v1Result.ID | Should -Be $v2Result.ID
                $v1Result.Title | Should -Be $v2Result.Title
                $v1Result.MediaType | Should -Be $v2Result.MediaType
                $v1Result.FileSize | Should -Be $v2Result.FileSize
                $v1Result.PageID | Should -Be $v2Result.PageID
            }

            It "both build the same sanitized filename from PageID and Title" {
                $v1Result.Filename | Should -Be $v2Result.Filename
            }
        }
    }
}
