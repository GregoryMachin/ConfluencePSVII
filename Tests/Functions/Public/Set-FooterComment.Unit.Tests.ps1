#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Set-FooterComment" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePS {
                param([Uri]$Uri, [string]$Body)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                ConvertFrom-Json '{"id": "327680", "status": "current", "body": {"storage": {"value": "<p>Updated</p>"}}}'
            }
            Mock Get-FooterComment -ModuleName ConfluencePS {
                [ConfluencePS.Comment]@{ ID = 327680; Body = '<p>Old</p>'; Version = [ConfluencePS.Version]@{ Number = 2 } }
            }
        }

        It "reads the original comment and increments its version on the v1 route" {
            $result = Set-FooterComment -ApiUri "https://example.com/wiki/rest/api" -CommentID 327680 -Body "<p>Updated</p>" -Confirm:$false

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/327680"
            $script:lastBody.version.number | Should -Be 3
            $result | Should -BeOfType [ConfluencePS.Comment]
        }

        Context "Pipeline binding" {
            It "accepts -CommentID from the pipeline by property name alongside -Body" {
                # Piping an object while also passing -Body forces parameter-set
                # resolution to 'byParameters'; CommentID must still bind from the
                # piped object's ID property in that case, not just from
                # -CommentID/pipeline-by-value.
                $pipedComment = [PSCustomObject]@{ ID = 327680 }

                $null = $pipedComment | Set-FooterComment -ApiUri "https://example.com/wiki/rest/api" -Body "<p>Updated</p>" -Confirm:$false

                $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/327680"
            }
        }

        Context "Cloud v2 routing" {
            It "routes to the v2 footer-comments route and increments the version" {
                $result = Set-FooterComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -CommentID 327680 -Body "<p>Updated</p>" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/footer-comments/327680"
                $script:lastBody.id | Should -Be '327680'
                $script:lastBody.version.number | Should -Be 3
                $result | Should -BeOfType [ConfluencePS.Comment]
            }

            It "forwards -BaseUri/-DeploymentType to the internal Get-FooterComment call" {
                $null = Set-FooterComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -CommentID 327680 -Body "<p>Updated</p>" -Confirm:$false

                Should -Invoke -CommandName Get-FooterComment -ModuleName ConfluencePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $BaseUri -eq 'https://example.atlassian.net' -and $DeploymentType -eq 'Cloud'
                }
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = Set-FooterComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -CommentID 327680 -Body "<p>Updated</p>" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/327680"
            }
        }
    }
}
