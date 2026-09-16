#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Resolve-OAuthResource" -Tag 'Unit' {
        BeforeEach {
            $script:resources = @(
                [ConfluencePS.OAuthResource]@{
                    CloudId = '11223344-a1b2-3b33-c444-def123456789'
                    Name    = 'Example Site'
                    Url     = [Uri]'https://example.atlassian.net/'
                    Scopes  = @('read:confluence-content.all')
                },
                [ConfluencePS.OAuthResource]@{
                    CloudId = '99887766-a1b2-3b33-c444-def123456789'
                    Name    = 'Other Site'
                    Url     = [Uri]'https://other.atlassian.net/'
                    Scopes  = @('read:confluence-content.all')
                }
            )
        }

        It "returns every resource when no selector is given" {
            (Resolve-OAuthResource -Resource $script:resources).Count | Should -Be 2
        }

        It "filters by CloudId" {
            (Resolve-OAuthResource -Resource $script:resources -CloudId '11223344-a1b2-3b33-c444-def123456789').Name | Should -Be 'Example Site'
        }

        It "filters by SiteName" {
            (Resolve-OAuthResource -Resource $script:resources -SiteName 'Other Site').CloudId | Should -Be '99887766-a1b2-3b33-c444-def123456789'
        }

        It "filters by SiteUrl" {
            (Resolve-OAuthResource -Resource $script:resources -SiteUrl 'https://other.atlassian.net').Name | Should -Be 'Other Site'
        }

        It "throws ItemNotFoundException when nothing matches" {
            { Resolve-OAuthResource -Resource $script:resources -CloudId '00000000-0000-0000-0000-000000000000' } |
                Should -Throw -ExceptionType ([System.Management.Automation.ItemNotFoundException])
        }

        It "throws when more than one selector is given" {
            { Resolve-OAuthResource -Resource $script:resources -CloudId '11223344-a1b2-3b33-c444-def123456789' -SiteName 'Other Site' } | Should -Throw
        }
    }
}
