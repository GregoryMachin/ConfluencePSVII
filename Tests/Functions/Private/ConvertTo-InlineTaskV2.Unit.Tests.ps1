#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "ConvertTo-InlineTaskV2" -Tag 'Unit' {
        BeforeAll {
            $script:fullJson = @'
{
    "id": "589824",
    "localId": "3",
    "pageId": "196608",
    "status": "incomplete",
    "body": {
        "storage": {
            "representation": "storage",
            "value": "Follow up with legal"
        }
    },
    "createdBy": "712020:aaaa",
    "assignedTo": "712020:bbbb",
    "completedBy": null,
    "createdAt": "2023-05-24T15:11:22.331Z",
    "dueAt": "2023-06-01T00:00:00.000Z",
    "completedAt": null,
    "version": {
        "number": 1,
        "authorId": "712020:aaaa",
        "createdAt": "2023-05-24T15:11:22.331Z"
    },
    "unexpectedField": "ignored"
}
'@
            $script:fullObject = ConvertFrom-Json -InputObject $fullJson
        }

        Context "Object conversion" {
            It "creates a ConfluencePS.InlineTask object" {
                $result = ConvertTo-InlineTaskV2 -InputObject $fullObject

                $result | Should -BeOfType [ConfluencePS.InlineTask]
            }

            It "does not throw on an unrecognized field" {
                { ConvertTo-InlineTaskV2 -InputObject $fullObject } | Should -Not -Throw
            }
        }

        Context "Property mapping" {
            BeforeAll {
                $script:result = ConvertTo-InlineTaskV2 -InputObject $fullObject
            }

            It "casts numeric-string ids to UInt64" {
                $result.ID | Should -Be 589824
                $result.LocalID | Should -Be 3
                $result.PageID | Should -Be 196608
            }

            It "maps status and body directly" {
                $result.Status | Should -Be 'incomplete'
                $result.Body | Should -Be 'Follow up with legal'
            }

            It "converts createdBy and assignedTo account IDs to User objects" {
                $result.CreatedBy.UserKey | Should -Be '712020:aaaa'
                $result.AssignedTo.UserKey | Should -Be '712020:bbbb'
            }

            It "leaves CompletedBy unset when the task has not been completed" {
                $result.CompletedBy | Should -BeNullOrEmpty
            }

            It "converts createdAt and dueAt to DateTime" {
                $result.CreatedAt | Should -BeOfType [DateTime]
                $result.DueAt | Should -BeOfType [DateTime]
            }

            It "leaves CompletedAt unset when the task has not been completed" {
                $result.CompletedAt | Should -BeNullOrEmpty
            }

            It "converts the nested version object" {
                $result.Version.Number | Should -Be 1
            }
        }

        Context "Missing users (an unassigned, incomplete task)" {
            It "handles a task with no assignee and no completer" {
                $json = ConvertFrom-Json -InputObject '{"id": "1", "status": "incomplete", "createdBy": "712020:aaaa", "createdAt": "2023-05-24T15:11:22.331Z"}'

                $result = ConvertTo-InlineTaskV2 -InputObject $json

                $result.AssignedTo | Should -BeNullOrEmpty
                $result.CompletedBy | Should -BeNullOrEmpty
                $result.DueAt | Should -BeNullOrEmpty
            }
        }

        Context "Pipeline support" {
            It "accepts input from the pipeline" {
                $result = $fullObject | ConvertTo-InlineTaskV2

                $result | Should -Not -BeNullOrEmpty
            }

            It "handles array input" {
                $result = @($fullObject, $fullObject) | ConvertTo-InlineTaskV2

                @($result).Count | Should -Be 2
            }

            It "does not throw on null input" {
                { $null | ConvertTo-InlineTaskV2 } | Should -Not -Throw
            }
        }
    }
}
