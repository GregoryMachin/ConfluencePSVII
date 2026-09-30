#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
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

        Context "OAuth access token configuration (Task 56)" {
            AfterEach {
                $global:PSDefaultParameterValues.Remove("Get-ConfluenceSpace:PersonalAccessToken")
                $script:PSDefaultParameterValues.Remove("Get-ConfluenceSpace:PersonalAccessToken")
            }

            It "configures an OAuth Cloud session from -OAuthAccessToken and -CloudId" {
                $token = ConvertTo-SecureString -String 'my-oauth-token' -AsPlainText -Force

                Set-Info -OAuthAccessToken $token -CloudId '11223344-a1b2-3b33-c444-def123456789'

                $global:PSDefaultParameterValues["Get-ConfluenceSpace:ApiUri"] |
                    Should -BeExactly "https://api.atlassian.com/ex/confluence/11223344-a1b2-3b33-c444-def123456789/wiki/rest/api"
                $global:PSDefaultParameterValues["Get-ConfluenceSpace:PersonalAccessToken"] | Should -BeExactly 'my-oauth-token'
                $script:ConfluenceRequestContext.DeploymentType | Should -BeExactly "Cloud"
                $script:ConfluenceRequestContext.AuthenticationType | Should -BeExactly "OAuth"
                $script:ConfluenceRequestContext.CloudId | Should -BeExactly '11223344-a1b2-3b33-c444-def123456789'
            }

            It "throws when both -BaseUri and -OAuthAccessToken are supplied" {
                $token = ConvertTo-SecureString -String 'my-oauth-token' -AsPlainText -Force

                { Set-Info -BaseUri "https://example.com" -OAuthAccessToken $token -CloudId '11223344-a1b2-3b33-c444-def123456789' } |
                    Should -Throw "*either -BaseUri or -OAuthAccessToken*"
            }

            It "throws when -CloudId is missing" {
                $token = ConvertTo-SecureString -String 'my-oauth-token' -AsPlainText -Force

                { Set-Info -OAuthAccessToken $token } | Should -Throw "*-CloudId is required*"
            }

            It "throws when -CloudId is not a UUID" {
                $token = ConvertTo-SecureString -String 'my-oauth-token' -AsPlainText -Force

                { Set-Info -OAuthAccessToken $token -CloudId 'not-a-guid' } | Should -Throw "*must be a UUID*"
            }
        }

        Context "OAuth client-credentials configuration (Task 56)" {
            AfterEach {
                $global:PSDefaultParameterValues.Remove("Get-ConfluenceSpace:PersonalAccessToken")
                $script:PSDefaultParameterValues.Remove("Get-ConfluenceSpace:PersonalAccessToken")
            }

            BeforeEach {
                Mock Request-OAuthClientCredentialsToken -ModuleName ConfluencePSVII {
                    [PSCustomObject]@{
                        AccessToken = (ConvertTo-SecureString -String 'client-credentials-token' -AsPlainText -Force)
                        ExpiresAt   = (Get-Date).AddHours(1)
                        TokenType   = 'Bearer'
                        Scopes      = @('read:confluence-content.all')
                    }
                }

                Mock Get-OAuthResource -ModuleName ConfluencePSVII {
                    [ConfluencePSVII.OAuthResource]@{
                        CloudId = '11223344-a1b2-3b33-c444-def123456789'
                        Name    = 'Example Site'
                        Url     = [Uri]'https://example.atlassian.net/'
                        Scopes  = @('read:confluence-content.all')
                    }
                }
            }

            It "exchanges client credentials and configures the single reachable site" {
                $secret = ConvertTo-SecureString -String 'my-secret' -AsPlainText -Force

                Set-Info -OAuthClientId 'my-client-id' -OAuthClientSecret $secret

                Should -Invoke Request-OAuthClientCredentialsToken -ModuleName ConfluencePSVII -Times 1
                $global:PSDefaultParameterValues["Get-ConfluenceSpace:ApiUri"] |
                    Should -BeExactly "https://api.atlassian.com/ex/confluence/11223344-a1b2-3b33-c444-def123456789/wiki/rest/api"
                $global:PSDefaultParameterValues["Get-ConfluenceSpace:PersonalAccessToken"] | Should -BeExactly 'client-credentials-token'
                $script:ConfluenceRequestContext.CloudId | Should -BeExactly '11223344-a1b2-3b33-c444-def123456789'
            }

            It "forwards a -SiteUrl selector to Get-ConfluenceOAuthResource" {
                $secret = ConvertTo-SecureString -String 'my-secret' -AsPlainText -Force

                Set-Info -OAuthClientId 'my-client-id' -OAuthClientSecret $secret -SiteUrl 'https://example.atlassian.net'

                Should -Invoke Get-OAuthResource -ModuleName ConfluencePSVII -ParameterFilter { $SiteUrl -eq 'https://example.atlassian.net' }
            }

            It "throws when only -OAuthClientId is supplied" {
                { Set-Info -OAuthClientId 'my-client-id' } | Should -Throw "*must be supplied together*"
            }

            It "throws when -OAuthClientId and -OAuthAccessToken are both supplied" {
                $token = ConvertTo-SecureString -String 'my-oauth-token' -AsPlainText -Force
                $secret = ConvertTo-SecureString -String 'my-secret' -AsPlainText -Force

                { Set-Info -OAuthAccessToken $token -CloudId '11223344-a1b2-3b33-c444-def123456789' -OAuthClientId 'my-client-id' -OAuthClientSecret $secret } |
                    Should -Throw "*either -OAuthAccessToken or -OAuthClientId*"
            }

            It "throws when -SiteName is supplied without client credentials" {
                { Set-Info -SiteName 'Example Site' } | Should -Throw "*only valid together with*"
            }

            It "throws when the client credentials reach no site" {
                Mock Get-OAuthResource -ModuleName ConfluencePSVII { }
                $secret = ConvertTo-SecureString -String 'my-secret' -AsPlainText -Force

                { Set-Info -OAuthClientId 'my-client-id' -OAuthClientSecret $secret } |
                    Should -Throw -ExceptionType ([System.Management.Automation.ItemNotFoundException])
            }

            It "throws when the client credentials reach more than one site with no selector" {
                Mock Get-OAuthResource -ModuleName ConfluencePSVII {
                    @(
                        [ConfluencePSVII.OAuthResource]@{ CloudId = '11223344-a1b2-3b33-c444-def123456789'; Name = 'Example Site'; Url = [Uri]'https://example.atlassian.net/' }
                        [ConfluencePSVII.OAuthResource]@{ CloudId = '99887766-a1b2-3b33-c444-def123456789'; Name = 'Other Site'; Url = [Uri]'https://other.atlassian.net/' }
                    )
                }
                $secret = ConvertTo-SecureString -String 'my-secret' -AsPlainText -Force

                { Set-Info -OAuthClientId 'my-client-id' -OAuthClientSecret $secret } |
                    Should -Throw -ExceptionType ([System.InvalidOperationException])
            }
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
