#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Get-PageAncestor" -Tag 'Unit' {
        BeforeEach {
            $script:lastUri = $null
            $script:lastGetParameters = $null

            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([string]$Uri, [hashtable]$GetParameters)
                $script:lastUri = $Uri
                $script:lastGetParameters = $GetParameters
                ConvertFrom-Json '{"id": "196608", "ancestors": [{"id": "1", "status": "current", "title": "Root"}, {"id": "2", "status": "current", "title": "Parent"}]}'
            }
        }

        It "requests the v1 content route with expand=ancestors" {
            $result = Get-PageAncestor -ApiUri "https://example.com/wiki/rest/api" -PageID 196608

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/196608"
            $script:lastGetParameters['expand'] | Should -Be 'ancestors'
        }

        It "returns the ancestors in root-to-parent order" {
            $result = @(Get-PageAncestor -ApiUri "https://example.com/wiki/rest/api" -PageID 196608)

            $result.Count | Should -Be 2
            $result[0].Title | Should -Be 'Root'
            $result[1].Title | Should -Be 'Parent'
            $result | ForEach-Object { $_ | Should -BeOfType [ConfluencePSVII.Page] }
        }

        It "returns nothing for a top-level page with no ancestors" {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                ConvertFrom-Json '{"id": "196608"}'
            }

            $result = @(Get-PageAncestor -ApiUri "https://example.com/wiki/rest/api" -PageID 196608)

            $result.Count | Should -Be 0
        }

        Context "Cloud v2 routing" {
            BeforeEach {
                Mock Invoke-Method -ModuleName ConfluencePSVII {
                    param([Uri]$Uri)
                    $script:lastUri = $Uri.AbsoluteUri
                    ConvertFrom-Json '{"id": "1", "status": "current", "title": "Root"}'
                }
            }

            It "routes to the dedicated v2 ancestors route" {
                $result = Get-PageAncestor -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 196608

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/pages/196608/ancestors"
                $result | Should -BeOfType [ConfluencePSVII.Page]
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = Get-PageAncestor -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -PageID 196608

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/196608"
            }
        }
    }
}
