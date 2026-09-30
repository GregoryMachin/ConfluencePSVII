#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Remove-Label" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri)
                $script:lastUri = $Uri.AbsoluteUri
            }
        }

        It "always uses the v1 label route, since Cloud v2 has no label mutation operation" {
            $null = Remove-Label -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 100 -Label "how-to" -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/100/label?name=how-to"
        }

        It "forwards -BaseUri and -DeploymentType to the internal Get-Label lookup when -Label is not supplied" {
            Mock Get-Label -ModuleName ConfluencePSVII {
                [ConfluencePSVII.ContentLabelSet]@{ Labels = @([ConfluencePSVII.Label]@{ Name = 'how-to' }) }
            }

            $null = Remove-Label -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 100 -Confirm:$false

            Should -Invoke -CommandName Get-Label -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It -ParameterFilter {
                $BaseUri -eq "https://example.atlassian.net" -and $DeploymentType -eq 'Cloud'
            }
        }
    }
}
