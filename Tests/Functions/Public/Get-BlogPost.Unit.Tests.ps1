#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Get-BlogPost" -Tag 'Unit' {
        BeforeEach {
            $script:lastUri = $null
            $script:lastCql = $null
            $script:lastGetParameters = $null

            Mock Invoke-Method -ModuleName ConfluencePS {
                param(
                    [string]$Uri,
                    [hashtable]$GetParameters
                )

                $script:lastUri = $Uri
                $script:lastGetParameters = $GetParameters
                $script:lastCql = $GetParameters['cql']
                [ConfluencePS.BlogPost]::new()
            }
        }

        It "requests the v1 content route by ID with type=blogpost by default" {
            $null = Get-BlogPost -ApiUri "https://example.com/wiki/rest/api" -BlogPostID 100

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/100"
        }

        It "filters the v1 space listing to type=blogpost" {
            $null = Get-BlogPost -ApiUri "https://example.com/wiki/rest/api" -SpaceKey "HOTH"

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content"
            $script:lastGetParameters['type'] | Should -Be 'blogpost'
            $script:lastGetParameters['spaceKey'] | Should -Be 'HOTH'
        }

        It "prefixes byQuery CQL with type=blogpost without pre-encoding" {
            $null = Get-BlogPost -ApiUri "https://example.com/wiki/rest/api" -Query 'space=HOTH and title~"*Object"'

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/search"
            $script:lastCql | Should -Be 'type=blogpost AND space=HOTH and title~"*Object"'
        }

        Context "Cloud v2 routing" {
            BeforeEach {
                Mock Invoke-Method -ModuleName ConfluencePS {
                    param([Uri]$Uri, [hashtable]$GetParameters)

                    $script:lastUri = $Uri.AbsoluteUri
                    $script:lastGetParameters = $GetParameters
                    ConvertFrom-Json '{"id": "262144", "status": "current", "title": "Example Blog Post", "body": {"storage": {"value": "<p>Hi</p>"}}}'
                }
                Mock Get-Space -ModuleName ConfluencePS {
                    [ConfluencePS.Space]@{ Id = 98307 }
                }
            }

            It "routes a byId request to the v2 blog post route and converts the v2 shape" {
                $result = Get-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -BlogPostID 262144

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/blogposts/262144"
                $result | Should -BeOfType [ConfluencePS.BlogPost]
                $result.ID | Should -Be 262144
                $result.Body | Should -Be '<p>Hi</p>'
            }

            It "resolves -SpaceKey to a numeric space-id via Get-Space for the collection route" {
                $null = Get-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -SpaceKey "TEST"

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/blogposts"
                $script:lastGetParameters['space-id'] | Should -Be 98307
                Should -Invoke -CommandName Get-Space -ModuleName ConfluencePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $SpaceKey -eq 'TEST' -and $DeploymentType -eq 'Cloud'
                }
            }

            It "requests body-format=storage unless -ExcludeBody is set" {
                $null = Get-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -BlogPostID 262144

                $script:lastGetParameters['body-format'] | Should -Be 'storage'
            }

            It "omits body-format when -ExcludeBody is set" {
                $null = Get-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -BlogPostID 262144 -ExcludeBody

                $script:lastGetParameters.ContainsKey('body-format') | Should -BeFalse
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = Get-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -BlogPostID 262144

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/262144"
            }

            It "uses the v1 route for Data Center regardless of -BaseUri" {
                $null = Get-BlogPost -ApiUri "https://dc.example.com/rest/api" -BaseUri "https://dc.example.com" -DeploymentType DataCenter -BlogPostID 262144

                $script:lastUri | Should -Be "https://dc.example.com/rest/api/content/262144"
            }
        }
    }
}
