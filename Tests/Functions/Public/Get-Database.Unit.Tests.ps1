#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Get-Database" -Tag 'Unit' {
        BeforeEach {
            $script:lastUri = $null
            $script:lastGetParameters = $null

            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri, [hashtable]$GetParameters)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastGetParameters = $GetParameters
                ConvertFrom-Json '{"id": "393216", "status": "current", "title": "Example Database", "spaceId": "98307"}'
            }
        }

        It "routes a byId request to the dedicated v2 database route" {
            $result = Get-Database -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DatabaseID 393216

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/databases/393216"
            $result | Should -BeOfType [ConfluencePSVII.Database]
        }

        It "requests one v2 route per DatabaseID" {
            $null = Get-Database -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DatabaseID 393216, 393217

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 2 -Scope It
        }

        Context "bySpace" {
            BeforeEach {
                Mock Get-Space -ModuleName ConfluencePSVII {
                    [ConfluencePSVII.Space]@{ Id = 98307 }
                }
            }

            It "resolves -SpaceKey to a numeric space-id via Get-Space and filters the collection" {
                $result = Get-Database -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceKey "TEST"

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/databases"
                $script:lastGetParameters['space-id'] | Should -Be 98307
                $result | Should -BeOfType [ConfluencePSVII.Database]
                Should -Invoke -CommandName Get-Space -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It -ParameterFilter {
                    $SpaceKey -eq 'TEST' -and $DeploymentType -eq 'Cloud'
                }
            }
        }

        It "throws when -BaseUri is not an HTTPS URI, since databases have no v1/Data Center equivalent" {
            { Get-Database -ApiUri "http://dc.example.com/rest/api" -BaseUri "http://dc.example.com" -DatabaseID 393216 } | Should -Throw
        }
    }
}
