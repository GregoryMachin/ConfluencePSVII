#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Get-Space" -Tag 'Unit' {
        BeforeEach {
            $script:lastGetParameters = $null

            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param(
                    [hashtable]$GetParameters
                )

                $script:lastGetParameters = $GetParameters
                [ConfluencePSVII.Space]::new()
            }
        }

        It "does not request metadata labels when listing spaces" {
            $null = Get-Space -ApiUri "https://example.com/wiki/rest/api"

            $script:lastGetParameters['expand'] | Should -BeExactly "description.plain,icon,homepage"
        }

        Context "Cloud v2 routing" {
            BeforeEach {
                Mock Invoke-Method -ModuleName ConfluencePSVII {
                    param([Uri]$Uri, [hashtable]$GetParameters)

                    $script:lastUri = $Uri.AbsoluteUri
                    $script:lastGetParameters = $GetParameters
                    ConvertFrom-Json '{"id": "98307", "key": "TEST", "name": "Test Space"}'
                }
            }

            It "routes an all-spaces request to the v2 spaces collection" {
                $result = Get-Space -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/spaces"
                $result | Should -BeOfType [ConfluencePSVII.Space]
                $result.Key | Should -Be 'TEST'
                $script:lastGetParameters.ContainsKey('keys') | Should -BeFalse
            }

            It "requests one v2 collection call with a comma-separated keys filter for multiple keys" {
                $null = Get-Space -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -SpaceKey TEST, OTHER

                $script:lastGetParameters['keys'] | Should -Be 'TEST,OTHER'
                Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It
            }

            It "requests description-format and include-icon" {
                $null = Get-Space -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud

                $script:lastGetParameters['description-format'] | Should -Be 'plain'
                $script:lastGetParameters['include-icon'] | Should -Be 'true'
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = Get-Space -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -SpaceKey TEST

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/space/TEST"
            }

            It "uses the v1 route for Data Center regardless of -BaseUri" {
                $null = Get-Space -ApiUri "https://dc.example.com/rest/api" -BaseUri "https://dc.example.com" -DeploymentType DataCenter -SpaceKey TEST

                $script:lastUri | Should -Be "https://dc.example.com/rest/api/space/TEST"
            }
        }
    }
}
