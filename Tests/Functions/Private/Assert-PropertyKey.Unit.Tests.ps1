#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Assert-PropertyKey" -Tag 'Unit' {
        It "accepts a plain alphanumeric key" {
            { Assert-PropertyKey -Key 'myKey123' } | Should -Not -Throw
        }

        It "accepts a key with dots, underscores, colons, and hyphens" {
            { Assert-PropertyKey -Key 'com.example:my_key-1' } | Should -Not -Throw
        }

        It "rejects an empty key" {
            { Assert-PropertyKey -Key '' } | Should -Throw
        }

        It "rejects a key starting with a non-alphanumeric character" {
            { Assert-PropertyKey -Key '.leadingDot' } | Should -Throw
        }

        It "rejects a key longer than 255 characters" {
            { Assert-PropertyKey -Key ('a' * 256) } | Should -Throw
        }

        It "rejects a key containing a space" {
            { Assert-PropertyKey -Key 'has space' } | Should -Throw
        }

        It "rejects a key that looks like it contains a secret" {
            { Assert-PropertyKey -Key 'apiToken' } | Should -Throw "*secret*"
        }

        It "rejects a prototype-pollution-shaped key" {
            { Assert-PropertyKey -Key '__proto__' } | Should -Throw
        }
    }
}
