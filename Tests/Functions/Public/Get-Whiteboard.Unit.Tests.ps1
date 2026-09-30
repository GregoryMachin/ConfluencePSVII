#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Get-Whiteboard" -Tag 'Unit' {
        BeforeEach {
            $script:lastUri = $null
            $script:lastGetParameters = $null

            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri, [hashtable]$GetParameters)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastGetParameters = $GetParameters
                ConvertFrom-Json '{"id": "524288", "status": "current", "title": "Example Whiteboard", "spaceId": "98307"}'
            }
        }

        It "routes a byId request to the dedicated v2 whiteboard route" {
            $result = Get-Whiteboard -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -WhiteboardID 524288

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/whiteboards/524288"
            $result | Should -BeOfType [ConfluencePSVII.Whiteboard]
        }

        It "requests one v2 route per WhiteboardID" {
            $null = Get-Whiteboard -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -WhiteboardID 524288, 524289

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 2 -Scope It
        }

        Context "bySpace" {
            BeforeEach {
                Mock Get-Space -ModuleName ConfluencePSVII {
                    [ConfluencePSVII.Space]@{ Id = 98307 }
                }
            }

            It "resolves -SpaceKey to a numeric space-id via Get-Space and filters the collection" {
                $result = Get-Whiteboard -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceKey "TEST"

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/whiteboards"
                $script:lastGetParameters['space-id'] | Should -Be 98307
                $result | Should -BeOfType [ConfluencePSVII.Whiteboard]
                Should -Invoke -CommandName Get-Space -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It -ParameterFilter {
                    $SpaceKey -eq 'TEST' -and $DeploymentType -eq 'Cloud'
                }
            }
        }

        It "throws when -BaseUri is not an HTTPS URI, since whiteboards have no v1/Data Center equivalent" {
            { Get-Whiteboard -ApiUri "http://dc.example.com/rest/api" -BaseUri "http://dc.example.com" -WhiteboardID 524288 } | Should -Throw
        }
    }
}
