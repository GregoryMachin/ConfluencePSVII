#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Set-InlineTask" -Tag 'Unit' {
        BeforeEach {
            Mock Get-InlineTask -ModuleName ConfluencePS {
                [ConfluencePS.InlineTask]@{ ID = 589824; Status = 'incomplete'; Version = [ConfluencePS.Version]@{ Number = 1 } }
            }
            Mock Invoke-Method -ModuleName ConfluencePS {
                param([Uri]$Uri, [string]$Body)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                ConvertFrom-Json '{"id": "589824", "status": "complete", "createdBy": "712020:aaaa", "createdAt": "2023-05-24T15:11:22.331Z"}'
            }
        }

        It "routes to the dedicated v2 task route and increments the version" {
            $result = Set-InlineTask -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -TaskID 589824 -Status complete -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/tasks/589824"
            $script:lastBody.id | Should -Be '589824'
            $script:lastBody.status | Should -Be 'complete'
            $script:lastBody.version.number | Should -Be 2
            $result | Should -BeOfType [ConfluencePS.InlineTask]
        }

        It "forwards -BaseUri to the internal Get-InlineTask call" {
            $null = Set-InlineTask -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -TaskID 589824 -Status complete -Confirm:$false

            Should -Invoke -CommandName Get-InlineTask -ModuleName ConfluencePS -Exactly -Times 1 -Scope It -ParameterFilter {
                $BaseUri -eq 'https://example.atlassian.net'
            }
        }

        It "supports reopening a completed task" {
            $null = Set-InlineTask -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -TaskID 589824 -Status incomplete -Confirm:$false

            $script:lastBody.status | Should -Be 'incomplete'
        }

        It "does not call Invoke-Method when -WhatIf is set" {
            $null = Set-InlineTask -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -TaskID 589824 -Status complete -WhatIf

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePS -Exactly -Times 0 -Scope It
        }
    }
}
