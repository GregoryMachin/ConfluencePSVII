#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Get-Label" -Tag 'Unit' {
        BeforeEach {
            Mock Get-Page -ModuleName ConfluencePS {
                $page = [ConfluencePS.Page]::new()
                $page.ID = @($PageID)[0]
                $page
            }
        }

        It "uses the v1 label route by default" {
            Mock Invoke-Method -ModuleName ConfluencePS {
                param([Uri]$Uri)
                $script:lastUri = $Uri.AbsoluteUri
                [ConfluencePS.Label]::new()
            }

            $result = Get-Label -ApiUri "https://example.com/wiki/rest/api" -PageID 100

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/100/label"
            $result | Should -BeOfType [ConfluencePS.ContentLabelSet]
            $result.Page.ID | Should -Be 100
        }

        Context "Cloud v2 routing" {
            BeforeEach {
                Mock Invoke-Method -ModuleName ConfluencePS {
                    param([Uri]$Uri)
                    $script:lastUri = $Uri.AbsoluteUri
                    [ConfluencePS.Label]::new()
                }
            }

            It "routes to the v2 labels route when -BaseUri and -DeploymentType Cloud are supplied" {
                $null = Get-Label -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 100

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/pages/100/labels"
            }

            It "forwards -BaseUri and -DeploymentType to the internal Get-Page lookup" {
                $null = Get-Label -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 100

                Should -Invoke -CommandName Get-Page -ModuleName ConfluencePS -Exactly -Times 1 -Scope It -ParameterFilter {
                    $BaseUri -eq "https://example.atlassian.net" -and $DeploymentType -eq 'Cloud'
                }
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = Get-Label -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -PageID 100

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/100/label"
            }

            It "uses the v1 route for Data Center regardless of -BaseUri" {
                $null = Get-Label -ApiUri "https://dc.example.com/rest/api" -BaseUri "https://dc.example.com" -DeploymentType DataCenter -PageID 100

                $script:lastUri | Should -Be "https://dc.example.com/rest/api/content/100/label"
            }
        }
    }
}
