#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Get-OAuthResource" -Tag 'Unit' {
        BeforeEach {
            $script:lastUri = $null
            $script:lastPersonalAccessToken = $null

            Mock Invoke-Method -ModuleName ConfluencePS {
                param([Uri]$Uri, [String]$PersonalAccessToken)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastPersonalAccessToken = $PersonalAccessToken
                ConvertFrom-Json '[
                    {
                        "id": "11223344-a1b2-3b33-c444-def123456789",
                        "name": "Example Site",
                        "url": "https://example.atlassian.net",
                        "scopes": ["read:confluence-content.all"]
                    },
                    {
                        "id": "99887766-a1b2-3b33-c444-def123456789",
                        "name": "Other Site",
                        "url": "https://other.atlassian.net",
                        "scopes": ["read:confluence-content.all"]
                    }
                ]'
            }

            $script:token = ConvertTo-SecureString -String 'my-oauth-token' -AsPlainText -Force
        }

        It "calls the accessible-resources endpoint with the token as a bearer credential" {
            $null = Get-OAuthResource -OAuthAccessToken $script:token

            $script:lastUri | Should -Be 'https://api.atlassian.com/oauth/token/accessible-resources'
            $script:lastPersonalAccessToken | Should -Be 'my-oauth-token'
        }

        It "returns every resource with no selector" {
            (Get-OAuthResource -OAuthAccessToken $script:token).Count | Should -Be 2
        }

        It "filters to a single resource by -CloudId" {
            $result = Get-OAuthResource -OAuthAccessToken $script:token -CloudId '11223344-a1b2-3b33-c444-def123456789'

            $result | Should -BeOfType [ConfluencePS.OAuthResource]
            $result.Name | Should -Be 'Example Site'
        }

        It "filters to a single resource by -SiteUrl" {
            (Get-OAuthResource -OAuthAccessToken $script:token -SiteUrl 'https://other.atlassian.net').Name | Should -Be 'Other Site'
        }

        It "throws when -OAuthAccessToken is empty" {
            $emptyToken = ConvertTo-SecureString -String ' ' -AsPlainText -Force
            { Get-OAuthResource -OAuthAccessToken $emptyToken } | Should -Throw
        }
    }
}
