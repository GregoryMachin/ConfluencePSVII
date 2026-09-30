#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Get-Folder" -Tag 'Unit' {
        BeforeEach {
            $script:lastUri = $null
            $script:lastGetParameters = $null

            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri, [hashtable]$GetParameters)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastGetParameters = $GetParameters
                ConvertFrom-Json '{"id": "458752", "status": "current", "title": "Example Folder", "spaceId": "98307"}'
            }
        }

        It "routes a byId request to the dedicated v2 folder route" {
            $result = Get-Folder -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -FolderID 458752

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/folders/458752"
            $result | Should -BeOfType [ConfluencePSVII.Folder]
        }

        It "requests one v2 route per FolderID" {
            $null = Get-Folder -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -FolderID 458752, 458753

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 2 -Scope It
        }

        Context "bySpace" {
            BeforeEach {
                Mock Get-Space -ModuleName ConfluencePSVII {
                    [ConfluencePSVII.Space]@{ Id = 98307 }
                }
            }

            It "resolves -SpaceKey to a numeric space-id via Get-Space and filters the collection" {
                $result = Get-Folder -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -SpaceKey "TEST"

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/folders"
                $script:lastGetParameters['space-id'] | Should -Be 98307
                $result | Should -BeOfType [ConfluencePSVII.Folder]
                Should -Invoke -CommandName Get-Space -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It -ParameterFilter {
                    $SpaceKey -eq 'TEST' -and $DeploymentType -eq 'Cloud'
                }
            }
        }

        It "throws when -BaseUri is not an HTTPS URI, since folders have no v1/Data Center equivalent" {
            { Get-Folder -ApiUri "http://dc.example.com/rest/api" -BaseUri "http://dc.example.com" -FolderID 458752 } | Should -Throw
        }
    }
}
