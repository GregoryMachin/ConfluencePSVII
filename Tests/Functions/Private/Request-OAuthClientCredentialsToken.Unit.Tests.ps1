#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Request-OAuthClientCredentialsToken" -Tag 'Unit' {
        BeforeEach {
            $script:lastUri = $null
            $script:lastBody = $null

            $script:clientSecret = ConvertTo-SecureString -String 'super-secret-value' -AsPlainText -Force
        }

        It "exchanges client credentials for an access token" {
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                param($Uri, $Body)
                $script:lastUri = $Uri
                $script:lastBody = [Text.Encoding]::UTF8.GetString($Body)
                [PSCustomObject]@{
                    Content = '{"access_token":"my-access-token","expires_in":3600,"token_type":"Bearer","scope":"read:confluence-content.all write:confluence-content"}'
                }
            }

            $result = Request-OAuthClientCredentialsToken -ClientId 'my-client-id' -ClientSecret $script:clientSecret

            $script:lastUri | Should -Be 'https://auth.atlassian.com/oauth/token'
            $script:lastBody | Should -Match '"client_id":"my-client-id"'
            $script:lastBody | Should -Match '"client_secret":"super-secret-value"'
            $script:lastBody | Should -Match '"grant_type":"client_credentials"'

            [System.Net.NetworkCredential]::new('', $result.AccessToken).Password | Should -Be 'my-access-token'
            $result.TokenType | Should -Be 'Bearer'
            $result.Scopes | Should -Be @('read:confluence-content.all', 'write:confluence-content')
        }

        It "throws when the client secret is empty" {
            $emptySecret = ConvertTo-SecureString -String ' ' -AsPlainText -Force

            { Request-OAuthClientCredentialsToken -ClientId 'my-client-id' -ClientSecret $emptySecret } | Should -Throw
        }

        It "redacts the client secret from an exchange-failure error message" {
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                throw [System.Net.WebException]::new('Request failed: super-secret-value is invalid')
            }

            { Request-OAuthClientCredentialsToken -ClientId 'my-client-id' -ClientSecret $script:clientSecret } |
                Should -Throw -ExceptionType ([System.InvalidOperationException])

            try {
                Request-OAuthClientCredentialsToken -ClientId 'my-client-id' -ClientSecret $script:clientSecret
            }
            catch {
                $_.Exception.Message | Should -Not -Match 'super-secret-value'
            }
        }

        It "throws when the response has no access token" {
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                [PSCustomObject]@{ Content = '{"expires_in":3600}' }
            }

            { Request-OAuthClientCredentialsToken -ClientId 'my-client-id' -ClientSecret $script:clientSecret } | Should -Throw
        }
    }
}
