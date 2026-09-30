#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "New-FooterComment" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri, [string]$Body)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                ConvertFrom-Json '{"id": "327680", "status": "current", "body": {"storage": {"value": "<p>Hi</p>"}}, "container": {"id": "196608", "type": "page"}}'
            }
        }

        It "uses the v1 content route by default" {
            $result = New-FooterComment -ApiUri "https://example.com/wiki/rest/api" -PageID 196608 -Body "<p>Hi</p>" -Confirm:$false

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content"
            $script:lastBody.type | Should -Be 'comment'
            $script:lastBody.container.id | Should -Be '196608'
            $result | Should -BeOfType [ConfluencePSVII.Comment]
        }

        It "adds an ancestors entry for a reply on v1" {
            $null = New-FooterComment -ApiUri "https://example.com/wiki/rest/api" -PageID 196608 -ParentCommentID 327679 -Body "<p>Reply</p>" -Confirm:$false

            $script:lastBody.ancestors[0].id | Should -Be '327679'
        }

        Context "Cloud v2 routing" {
            It "routes to the v2 footer-comments route and sends the flat body shape" {
                $result = New-FooterComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 196608 -Body "<p>Hi</p>" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/footer-comments"
                $script:lastBody.pageId | Should -Be '196608'
                $script:lastBody.body.representation | Should -Be 'storage'
                $script:lastBody.body.value | Should -Be '<p>Hi</p>'
                $result | Should -BeOfType [ConfluencePSVII.Comment]
            }

            It "sends parentCommentId for a reply on v2" {
                $null = New-FooterComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 196608 -ParentCommentID 327679 -Body "<p>Reply</p>" -Confirm:$false

                $script:lastBody.parentCommentId | Should -Be '327679'
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = New-FooterComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -PageID 196608 -Body "<p>Hi</p>" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content"
            }
        }
    }
}
