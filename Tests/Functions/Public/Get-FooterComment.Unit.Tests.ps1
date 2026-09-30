#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Get-FooterComment" -Tag 'Unit' {
        BeforeEach {
            $script:lastUri = $null

            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([string]$Uri)
                $script:lastUri = $Uri
                [ConfluencePSVII.Comment]::new()
            }
        }

        It "requests the v1 content route by ID" {
            $null = Get-FooterComment -ApiUri "https://example.com/wiki/rest/api" -CommentID 327680

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/327680"
        }

        It "requests the v1 child-comment route for a page" {
            $null = Get-FooterComment -ApiUri "https://example.com/wiki/rest/api" -PageID 196608

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/196608/child/comment"
        }

        Context "Cloud v2 routing" {
            BeforeEach {
                Mock Invoke-Method -ModuleName ConfluencePSVII {
                    param([Uri]$Uri)
                    $script:lastUri = $Uri.AbsoluteUri
                    ConvertFrom-Json '{"id": "327680", "status": "current", "pageId": "196608", "body": {"storage": {"value": "<p>Hi</p>"}}}'
                }
            }

            It "routes a byId request to the v2 footer-comments route and converts the v2 shape" {
                $result = Get-FooterComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -CommentID 327680

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/footer-comments/327680"
                $result | Should -BeOfType [ConfluencePSVII.Comment]
                $result.Type | Should -Be 'footer'
            }

            It "routes a byPage request to the v2 page footer-comments collection" {
                $null = Get-FooterComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 196608

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/pages/196608/footer-comments"
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = Get-FooterComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -CommentID 327680

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/327680"
            }
        }
    }
}
