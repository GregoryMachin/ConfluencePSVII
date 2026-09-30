#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Resolve-OAuthSiteUri" -Tag 'Unit' {
        It "normalizes a root-path atlassian.net URL" {
            Resolve-OAuthSiteUri -Url 'https://example.atlassian.net' | Should -Be 'https://example.atlassian.net/'
        }

        It "throws for a non-HTTPS scheme" {
            { Resolve-OAuthSiteUri -Url 'http://example.atlassian.net' } | Should -Throw
        }

        It "throws for a non-default port" {
            { Resolve-OAuthSiteUri -Url 'https://example.atlassian.net:8443' } | Should -Throw
        }

        It "throws for a non-atlassian.net host" {
            { Resolve-OAuthSiteUri -Url 'https://example.com' } | Should -Throw
        }

        It "throws for a URL with a path" {
            { Resolve-OAuthSiteUri -Url 'https://example.atlassian.net/wiki' } | Should -Throw
        }

        It "throws for a URL with a query string" {
            { Resolve-OAuthSiteUri -Url 'https://example.atlassian.net/?a=1' } | Should -Throw
        }

        It "throws for a URL with user info" {
            { Resolve-OAuthSiteUri -Url 'https://user:pass@example.atlassian.net/' } | Should -Throw
        }
    }
}
