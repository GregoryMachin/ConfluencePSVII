#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Resolve-OAuthBaseUri" -Tag 'Unit' {
        It "builds the Cloud API gateway URI for a valid CloudId" {
            Resolve-OAuthBaseUri -CloudId '11223344-a1b2-3b33-c444-def123456789' |
                Should -Be "https://api.atlassian.com/ex/confluence/11223344-a1b2-3b33-c444-def123456789"
        }

        It "throws when CloudId is not a UUID" {
            { Resolve-OAuthBaseUri -CloudId 'not-a-guid' } | Should -Throw
        }
    }
}
