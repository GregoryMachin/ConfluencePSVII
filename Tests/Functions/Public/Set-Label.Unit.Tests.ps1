#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Set-Label" -Tag 'Unit' {
        BeforeEach {
            Mock Get-Page -ModuleName ConfluencePSVII {
                $page = [ConfluencePSVII.Page]::new()
                $page.ID = @($PageID)[0]
                $page
            }
            Mock Remove-Label -ModuleName ConfluencePSVII {}
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri)
                $script:lastUri = $Uri.AbsoluteUri
                [ConfluencePSVII.Label]::new()
            }
        }

        It "always uses the v1 label route, since Cloud v2 has no label mutation operation" {
            $null = Set-Label -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 100 -Label "how-to" -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/100/label"
        }

        It "forwards -BaseUri and -DeploymentType to the internal Get-Page and Remove-Label calls" {
            $null = Set-Label -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 100 -Label "how-to" -Confirm:$false

            Should -Invoke -CommandName Get-Page -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It -ParameterFilter {
                $BaseUri -eq "https://example.atlassian.net" -and $DeploymentType -eq 'Cloud'
            }
            Should -Invoke -CommandName Remove-Label -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It -ParameterFilter {
                $BaseUri -eq "https://example.atlassian.net" -and $DeploymentType -eq 'Cloud'
            }
        }
    }
}
