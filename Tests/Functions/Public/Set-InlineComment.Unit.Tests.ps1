#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Set-InlineComment" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri, [string]$Body)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                ConvertFrom-Json '{"id": "327680", "status": "current", "body": {"storage": {"value": "<p>Updated</p>"}}}'
            }
            Mock Get-InlineComment -ModuleName ConfluencePSVII {
                [ConfluencePSVII.Comment]@{ ID = 327680; Body = '<p>Old</p>'; Version = [ConfluencePSVII.Version]@{ Number = 1 } }
            }
        }

        It "reads the original comment and increments its version on the v1 route" {
            $result = Set-InlineComment -ApiUri "https://example.com/wiki/rest/api" -CommentID 327680 -Body "<p>Updated</p>" -Confirm:$false

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/327680"
            $script:lastBody.version.number | Should -Be 2
            $result | Should -BeOfType [ConfluencePSVII.Comment]
        }

        Context "Pipeline binding" {
            It "accepts -CommentID from the pipeline by property name alongside -Body" {
                # Piping an object while also passing -Body forces parameter-set
                # resolution to 'byParameters'; CommentID must still bind from the
                # piped object's ID property in that case, not just from
                # -CommentID/pipeline-by-value.
                $pipedComment = [PSCustomObject]@{ ID = 327680 }

                $null = $pipedComment | Set-InlineComment -ApiUri "https://example.com/wiki/rest/api" -Body "<p>Updated</p>" -Confirm:$false

                $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/327680"
            }
        }

        Context "Cloud v2 routing" {
            It "routes to the dedicated v2 inline-comments route and increments the version" {
                $result = Set-InlineComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -CommentID 327680 -Body "<p>Updated</p>" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/inline-comments/327680"
                $script:lastBody.version.number | Should -Be 2
                $result | Should -BeOfType [ConfluencePSVII.Comment]
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = Set-InlineComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -CommentID 327680 -Body "<p>Updated</p>" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/327680"
            }
        }
    }
}
