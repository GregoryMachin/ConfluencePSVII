#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "New-BlogPost" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri, [string]$Body)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                [ConfluencePSVII.BlogPost]::new()
            }
        }

        It "uses the v1 content route by default" {
            $null = New-BlogPost -ApiUri "https://example.com/wiki/rest/api" -Title "Example" -SpaceKey "TEST" -Body "<p>Hi</p>" -Confirm:$false

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content"
            $script:lastBody.type | Should -Be 'blogpost'
            $script:lastBody.space.key | Should -Be "TEST"
        }

        Context "Cloud v2 routing" {
            BeforeEach {
                Mock Get-Space -ModuleName ConfluencePSVII {
                    [ConfluencePSVII.Space]@{ Id = 98307 }
                }
            }

            It "routes to the v2 blogposts route and sends the flat body shape" {
                $result = New-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -Title "Example" -SpaceKey "TEST" -Body "<p>Hi</p>" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/blogposts"
                $script:lastBody.status | Should -Be 'current'
                $script:lastBody.title | Should -Be 'Example'
                $script:lastBody.body.representation | Should -Be 'storage'
                $script:lastBody.body.value | Should -Be '<p>Hi</p>'
                $result | Should -BeOfType [ConfluencePSVII.BlogPost]
            }

            It "resolves -SpaceKey to a numeric spaceId via Get-Space" {
                $null = New-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -Title "Example" -SpaceKey "TEST" -Body "<p>Hi</p>" -Confirm:$false

                $script:lastBody.spaceId | Should -Be '98307'
                Should -Invoke -CommandName Get-Space -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It -ParameterFilter {
                    $SpaceKey -eq 'TEST' -and $DeploymentType -eq 'Cloud'
                }
            }

            It "uses -Space.Id directly without calling Get-Space when already known" {
                $space = [ConfluencePSVII.Space]@{ Id = 55555; Key = 'TEST' }

                $null = New-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -Title "Example" -Space $space -Body "<p>Hi</p>" -Confirm:$false

                $script:lastBody.spaceId | Should -Be '55555'
                Should -Invoke -CommandName Get-Space -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It
            }

            It "accepts a BlogPost object through -InputObject" {
                $blogPost = [ConfluencePSVII.BlogPost]@{ Title = "Example"; Body = "<p>Hi</p>"; Space = [ConfluencePSVII.Space]@{ Id = 55555 } }

                $null = New-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -InputObject $blogPost -Confirm:$false

                $script:lastBody.spaceId | Should -Be '55555'
                $script:lastBody.title | Should -Be 'Example'
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = New-BlogPost -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -Title "Example" -SpaceKey "TEST" -Body "<p>Hi</p>" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content"
            }
        }
    }
}
