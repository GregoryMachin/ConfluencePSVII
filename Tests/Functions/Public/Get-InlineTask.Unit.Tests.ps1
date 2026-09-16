#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Get-InlineTask" -Tag 'Unit' {
        BeforeEach {
            $script:lastUri = $null
            $script:lastGetParameters = $null

            Mock Invoke-Method -ModuleName ConfluencePS {
                param([Uri]$Uri, [hashtable]$GetParameters)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastGetParameters = $GetParameters
                ConvertFrom-Json '{"id": "589824", "status": "incomplete", "createdBy": "712020:aaaa", "createdAt": "2023-05-24T15:11:22.331Z"}'
            }
        }

        It "routes a byId request to the dedicated v2 task route" {
            $result = Get-InlineTask -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -TaskID 589824

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/tasks/589824"
            $result | Should -BeOfType [ConfluencePS.InlineTask]
        }

        It "requests one v2 route per TaskID" {
            $null = Get-InlineTask -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -TaskID 589824, 589825

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 2 -Scope It
        }

        Context "byFilter" {
            It "routes to the task collection with no filters by default" {
                $result = Get-InlineTask -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net"

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/tasks"
                $result | Should -BeOfType [ConfluencePS.InlineTask]
            }

            It "forwards -PageID and -SpaceID filters" {
                $null = Get-InlineTask -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -PageID 196608 -SpaceID 98307

                $script:lastGetParameters['page-id'] | Should -Be 196608
                $script:lastGetParameters['space-id'] | Should -Be 98307
            }

            It "forwards -Status and -AssignedTo filters" {
                $null = Get-InlineTask -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -Status complete -AssignedTo "712020:aaaa"

                $script:lastGetParameters['status'] | Should -Be 'complete'
                $script:lastGetParameters['assigned-to'] | Should -Be '712020:aaaa'
            }

            It "forwards -DueAfter/-DueBefore as UTC ISO-8601 strings" {
                $null = Get-InlineTask -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DueAfter ([DateTime]'2023-01-01Z') -DueBefore ([DateTime]'2023-12-31Z')

                $script:lastGetParameters['due-at-from'] | Should -Match '^2023-01-01'
                $script:lastGetParameters['due-at-to'] | Should -Match '^2023-12-31'
            }

            It "does not add a filter parameter when its value is not supplied" {
                $null = Get-InlineTask -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net"

                $script:lastGetParameters.ContainsKey('status') | Should -BeFalse
                $script:lastGetParameters.ContainsKey('assigned-to') | Should -BeFalse
            }
        }

        It "throws when -BaseUri is not an HTTPS URI, since inline tasks have no v1/Data Center equivalent" {
            { Get-InlineTask -ApiUri "http://dc.example.com/rest/api" -BaseUri "http://dc.example.com" -TaskID 589824 } | Should -Throw
        }
    }
}
