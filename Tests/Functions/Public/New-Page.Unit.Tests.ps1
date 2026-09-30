#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "New-Page" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri, [string]$Body)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                [ConfluencePSVII.Page]::new()
            }
        }

        It "uses the v1 content route by default" {
            $null = New-Page -ApiUri "https://example.com/wiki/rest/api" -Title "Example" -SpaceKey "TEST" -Body "<p>Hi</p>" -Confirm:$false

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content"
            $script:lastBody.space.key | Should -Be "TEST"
        }

        Context "Cloud v2 routing" {
            BeforeEach {
                Mock Get-Space -ModuleName ConfluencePSVII {
                    [ConfluencePSVII.Space]@{ Id = 98307 }
                }
            }

            It "routes to the v2 pages route and sends the flat body shape" {
                $result = New-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -Title "Example" -SpaceKey "TEST" -Body "<p>Hi</p>" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/pages"
                $script:lastBody.status | Should -Be 'current'
                $script:lastBody.title | Should -Be 'Example'
                $script:lastBody.body.representation | Should -Be 'storage'
                $script:lastBody.body.value | Should -Be '<p>Hi</p>'
                $result | Should -BeOfType [ConfluencePSVII.Page]
            }

            It "resolves -SpaceKey to a numeric spaceId via Get-Space" {
                $null = New-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -Title "Example" -SpaceKey "TEST" -Body "<p>Hi</p>" -Confirm:$false

                $script:lastBody.spaceId | Should -Be '98307'
                Should -Invoke -CommandName Get-Space -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It -ParameterFilter {
                    $SpaceKey -eq 'TEST' -and $DeploymentType -eq 'Cloud'
                }
            }

            It "uses -Space.Id directly without calling Get-Space when already known" {
                $space = [ConfluencePSVII.Space]@{ Id = 55555; Key = 'TEST' }

                $null = New-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -Title "Example" -Space $space -Body "<p>Hi</p>" -Confirm:$false

                $script:lastBody.spaceId | Should -Be '55555'
                Should -Invoke -CommandName Get-Space -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It
            }

            It "sends parentId instead of an ancestors array" {
                $null = New-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -Title "Example" -SpaceKey "TEST" -Body "<p>Hi</p>" -ParentID 500 -Confirm:$false

                $script:lastBody.parentId | Should -Be '500'
                $script:lastBody.PSObject.Properties.Name | Should -Not -Contain 'ancestors'
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = New-Page -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -Title "Example" -SpaceKey "TEST" -Body "<p>Hi</p>" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content"
            }
        }
    }
}
