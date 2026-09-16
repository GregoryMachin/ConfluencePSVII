#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Get-InlineComment" -Tag 'Unit' {
        BeforeEach {
            $script:lastUri = $null

            Mock Invoke-Method -ModuleName ConfluencePS {
                param([string]$Uri)
                $script:lastUri = $Uri
                ConvertFrom-Json '{"id": "327680", "status": "current", "body": {"storage": {"value": "<p>Hi</p>"}}, "container": {"id": "196608", "type": "page"}}'
            }
        }

        It "requests the v1 content route by ID and converts with Type inline" {
            $result = Get-InlineComment -ApiUri "https://example.com/wiki/rest/api" -CommentID 327680

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/327680"
            $result.Type | Should -Be 'inline'
        }

        It "requests the same v1 child-comment route Get-FooterComment uses, since v1 has no dedicated inline resource" {
            $null = Get-InlineComment -ApiUri "https://example.com/wiki/rest/api" -PageID 196608

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/196608/child/comment"
        }

        Context "Cloud v2 routing" {
            BeforeEach {
                Mock Invoke-Method -ModuleName ConfluencePS {
                    param([Uri]$Uri)
                    $script:lastUri = $Uri.AbsoluteUri
                    ConvertFrom-Json '{"id": "327680", "status": "current", "pageId": "196608", "body": {"storage": {"value": "<p>Hi</p>"}}}'
                }
            }

            It "routes a byId request to the dedicated v2 inline-comments route" {
                $result = Get-InlineComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -CommentID 327680

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/inline-comments/327680"
                $result | Should -BeOfType [ConfluencePS.Comment]
                $result.Type | Should -Be 'inline'
            }

            It "routes a byPage request to the dedicated v2 page inline-comments collection" {
                $null = Get-InlineComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 196608

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/pages/196608/inline-comments"
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = Get-InlineComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -CommentID 327680

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/327680"
            }
        }
    }
}
