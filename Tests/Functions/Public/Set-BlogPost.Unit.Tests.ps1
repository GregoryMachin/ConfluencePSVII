#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Set-BlogPost" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri, [string]$Body)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                [ConfluencePSVII.BlogPost]::new()
            }
        }

        It "reads the original blog post and increments its version on the v1 route" {
            Mock Get-BlogPost -ModuleName ConfluencePSVII {
                [ConfluencePSVII.BlogPost]@{ ID = 262144; Title = 'Old title'; Body = '<p>Old</p>'; Version = [ConfluencePSVII.Version]@{ Number = 3 } }
            }

            $null = Set-BlogPost -ApiUri "https://example.com/wiki/rest/api" -BlogPostID 262144 -Title "New title" -Confirm:$false

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/262144"
            $script:lastBody.version.number | Should -Be 4
            $script:lastBody.title | Should -Be 'New title'
        }

        Context "Pipeline binding" {
            BeforeEach {
                Mock Get-BlogPost -ModuleName ConfluencePSVII {
                    [ConfluencePSVII.BlogPost]@{ ID = 262144; Title = 'Old title'; Body = '<p>Old</p>'; Version = [ConfluencePSVII.Version]@{ Number = 3 } }
                }
            }

            It "accepts -BlogPostID from the pipeline by property name alongside -Title" {
                # Piping an object while also passing -Title forces parameter-set
                # resolution to 'byParameters' (the only set with -Title); BlogPostID
                # must still bind from the piped object's ID property in that case,
                # not just from -BlogPostID/pipeline-by-value.
                $pipedBlogPost = [PSCustomObject]@{ ID = 262144 }

                $null = $pipedBlogPost | Set-BlogPost -ApiUri "https://example.com/wiki/rest/api" -Title "New title" -Confirm:$false

                $script:lastBody.title | Should -Be "New title"
            }
        }

        Context "Cloud v2 routing" {
            BeforeEach {
                Mock Get-BlogPost -ModuleName ConfluencePSVII {
                    [ConfluencePSVII.BlogPost]@{ ID = 262144; Title = 'Old title'; Body = '<p>Old</p>'; Version = [ConfluencePSVII.Version]@{ Number = 3 } }
                }
            }

            It "routes to the v2 blogposts route, increments the version, and sends the flat body shape" {
                $result = Set-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -BlogPostID 262144 -Title "New title" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/blogposts/262144"
                $script:lastBody.id | Should -Be '262144'
                $script:lastBody.title | Should -Be 'New title'
                $script:lastBody.version.number | Should -Be 4
                $script:lastBody.body.representation | Should -Be 'storage'
                $result | Should -BeOfType [ConfluencePSVII.BlogPost]
            }

            It "forwards -BaseUri/-DeploymentType to the internal Get-BlogPost call" {
                $null = Set-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -BlogPostID 262144 -Title "New title" -Confirm:$false

                Should -Invoke -CommandName Get-BlogPost -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It -ParameterFilter {
                    $BaseUri -eq 'https://example.atlassian.net' -and $DeploymentType -eq 'Cloud'
                }
            }

            It "keeps the original body when -Body is not supplied" {
                $null = Set-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -BlogPostID 262144 -Title "New title" -Confirm:$false

                $script:lastBody.body.value | Should -Be '<p>Old</p>'
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = Set-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -BlogPostID 262144 -Title "New title" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/262144"
            }
        }
    }
}
