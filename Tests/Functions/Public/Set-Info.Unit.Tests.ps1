#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Set-Info" -Tag 'Unit' {
        BeforeEach {
            $global:PSDefaultParameterValues.Remove("Get-ConfluenceSpace:ApiUri")
            $global:PSDefaultParameterValues.Remove("Get-ConfluencePage:ApiUri")
            $script:PSDefaultParameterValues.Remove("Get-ConfluenceSpace:ApiUri")
            $script:PSDefaultParameterValues.Remove("Get-ConfluencePage:ApiUri")
            $script:ConfluenceRequestContext = @{
                BaseUri            = $null
                ApiUri             = $null
                Product            = $null
                DeploymentType     = $null
                AuthenticationType = $null
                CloudId            = $null
            }
        }

        AfterAll {
            $global:PSDefaultParameterValues.Remove("Get-ConfluenceSpace:ApiUri")
            $global:PSDefaultParameterValues.Remove("Get-ConfluencePage:ApiUri")
        }

        It "preserves the old default BaseUri behavior" {
            Set-Info -BaseUri "https://wiki.example.com"

            $global:PSDefaultParameterValues["Get-ConfluenceSpace:ApiUri"] | Should -BeExactly "https://wiki.example.com/rest/api"
            $script:ConfluenceRequestContext.ApiUri.AbsoluteUri.TrimEnd('/') | Should -BeExactly "https://wiki.example.com/rest/api"
        }

        It "preserves an explicit /wiki Cloud path" {
            Set-Info -BaseUri "https://tenant.atlassian.net/wiki"

            $global:PSDefaultParameterValues["Get-ConfluenceSpace:ApiUri"] | Should -BeExactly "https://tenant.atlassian.net/wiki/rest/api"
        }

        It "normalizes explicit Cloud metadata to the /wiki REST API path" {
            $entry = [PSCustomObject]@{
                Uri            = "https://tenant.atlassian.net"
                Type           = "Confluence"
                Product        = "Confluence"
                DeploymentType = "Cloud"
            }

            Set-Info -BaseUri $entry

            $global:PSDefaultParameterValues["Get-ConfluenceSpace:ApiUri"] | Should -BeExactly "https://tenant.atlassian.net/wiki/rest/api"
            $script:ConfluenceRequestContext.DeploymentType | Should -BeExactly "Cloud"
        }

        It "preserves explicit Data Center custom context paths" {
            $entry = [PSCustomObject]@{
                Uri            = "https://wiki.example.com/confluence"
                Type           = "Confluence"
                Product        = "Confluence"
                DeploymentType = "DataCenter"
            }

            Set-Info -BaseUri $entry

            $global:PSDefaultParameterValues["Get-ConfluenceSpace:ApiUri"] | Should -BeExactly "https://wiki.example.com/confluence/rest/api"
            $script:ConfluenceRequestContext.DeploymentType | Should -BeExactly "DataCenter"
        }

        It "accepts configuration objects from the pipeline and keeps metadata" {
            [PSCustomObject]@{
                Uri                = "https://tenant.atlassian.net/wiki"
                Type               = "Confluence"
                Product            = "Confluence"
                DeploymentType     = "Cloud"
                AuthenticationType = "OAuth"
                CloudId            = "00000000-0000-0000-0000-000000000000"
            } | Set-Info

            $global:PSDefaultParameterValues["Get-ConfluencePage:ApiUri"] | Should -BeExactly "https://tenant.atlassian.net/wiki/rest/api"
            $script:ConfluenceRequestContext.AuthenticationType | Should -BeExactly "OAuth"
            $script:ConfluenceRequestContext.CloudId | Should -BeExactly "00000000-0000-0000-0000-000000000000"
        }

        It "rejects non-Confluence configuration entries" {
            $entry = [PSCustomObject]@{
                Uri     = "https://tenant.atlassian.net/wiki"
                Type    = "Jira"
                Product = "Jira"
            }

            { Set-Info -BaseUri $entry } | Should -Throw "*only accepts Confluence*"
        }

        It "rejects OAuth metadata for Data Center" {
            $entry = [PSCustomObject]@{
                Uri                = "https://wiki.example.com/confluence"
                Type               = "Confluence"
                Product            = "Confluence"
                DeploymentType     = "DataCenter"
                AuthenticationType = "OAuth"
            }

            { Set-Info -BaseUri $entry } | Should -Throw "*OAuth requires DeploymentType Cloud*"
        }

        It "rejects non-HTTPS Cloud configuration" {
            $entry = [PSCustomObject]@{
                Uri            = "http://tenant.atlassian.net/wiki"
                Type           = "Confluence"
                Product        = "Confluence"
                DeploymentType = "Cloud"
            }

            { Set-Info -BaseUri $entry } | Should -Throw "*Cloud configuration requires an HTTPS*"
        }

        Context "BaseUri and DeploymentType defaults (Task 44)" {
            AfterEach {
                $global:PSDefaultParameterValues.Remove("Get-ConfluencePage:BaseUri")
                $global:PSDefaultParameterValues.Remove("Get-ConfluencePage:DeploymentType")
                $global:PSDefaultParameterValues.Remove("Get-ConfluenceChildPage:BaseUri")
                $global:PSDefaultParameterValues.Remove("Get-ConfluenceChildPage:DeploymentType")
                $global:PSDefaultParameterValues.Remove("Set-ConfluenceInfo:BaseUri")
                $script:PSDefaultParameterValues.Remove("Get-ConfluencePage:BaseUri")
                $script:PSDefaultParameterValues.Remove("Get-ConfluencePage:DeploymentType")
                $script:PSDefaultParameterValues.Remove("Get-ConfluenceChildPage:BaseUri")
                $script:PSDefaultParameterValues.Remove("Get-ConfluenceChildPage:DeploymentType")
                $script:PSDefaultParameterValues.Remove("Set-ConfluenceInfo:BaseUri")
            }

            It "defaults -BaseUri on commands that declare it" {
                Set-Info -BaseUri "https://tenant.atlassian.net"

                $global:PSDefaultParameterValues["Get-ConfluencePage:BaseUri"] | Should -Not -BeNullOrEmpty
                $global:PSDefaultParameterValues["Get-ConfluenceChildPage:BaseUri"] | Should -Not -BeNullOrEmpty
            }

            It "defaults -DeploymentType only when explicit Cloud/DataCenter metadata is supplied" {
                $entry = [PSCustomObject]@{
                    Uri            = "https://tenant.atlassian.net"
                    Type           = "Confluence"
                    Product        = "Confluence"
                    DeploymentType = "Cloud"
                }

                Set-Info -BaseUri $entry

                $global:PSDefaultParameterValues["Get-ConfluencePage:DeploymentType"] | Should -Be "Cloud"
            }

            It "does not default -DeploymentType for a plain legacy BaseUri with no metadata" {
                Set-Info -BaseUri "https://tenant.atlassian.net"

                $global:PSDefaultParameterValues["Get-ConfluencePage:DeploymentType"] | Should -BeNullOrEmpty
            }

            It "never defaults Set-ConfluenceInfo's own -BaseURi parameter" {
                # Regression guard: -BaseURi (Set-ConfluenceInfo's own parameter) name-matches
                # the new -BaseUri default case-insensitively. If this were ever defaulted, a
                # later parameterless call would silently reuse the previous base URI instead
                # of clearing configuration.
                Set-Info -BaseUri "https://tenant.atlassian.net"

                $global:PSDefaultParameterValues["Set-ConfluenceInfo:BaseUri"] | Should -BeNullOrEmpty
                $global:PSDefaultParameterValues["Set-ConfluenceInfo:BaseURi"] | Should -BeNullOrEmpty
            }
        }
    }
}
