#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "ConvertTo-PropertyJson" -Tag 'Unit' {
        It "serializes a plain string value" {
            ConvertTo-PropertyJson -Value 'hello' | Should -Be '"hello"'
        }

        It "serializes a hashtable value" {
            $json = ConvertTo-PropertyJson -Value @{ a = 1; b = 'text' }

            $parsed = ConvertFrom-Json -InputObject $json
            $parsed.a | Should -Be 1
            $parsed.b | Should -Be 'text'
        }

        It "serializes a nested array value" {
            $json = ConvertTo-PropertyJson -Value @{ items = @(1, 2, 3) }

            (ConvertFrom-Json -InputObject $json).items | Should -Be @(1, 2, 3)
        }

        It "serializes a PSCustomObject value" {
            $json = ConvertTo-PropertyJson -Value ([PSCustomObject]@{ name = 'test' })

            (ConvertFrom-Json -InputObject $json).name | Should -Be 'test'
        }

        It "throws for a null value" {
            { ConvertTo-PropertyJson -Value $null } | Should -Throw
        }

        It "throws for a value containing a PSCredential" {
            $cred = [PSCredential]::new('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))

            { ConvertTo-PropertyJson -Value @{ auth = $cred } } | Should -Throw "*credentials*"
        }

        It "throws for a value containing a SecureString" {
            { ConvertTo-PropertyJson -Value (ConvertTo-SecureString 'pass' -AsPlainText -Force) } | Should -Throw
        }

        It "throws for a value containing a ScriptBlock" {
            { ConvertTo-PropertyJson -Value @{ code = { 1 + 1 } } } | Should -Throw "*script blocks*"
        }

        It "throws for a nested key that looks like it contains a secret" {
            { ConvertTo-PropertyJson -Value @{ config = @{ apiKey = 'x' } } } | Should -Throw "*secret*"
        }

        It "throws for a prototype-pollution-shaped nested key" {
            { ConvertTo-PropertyJson -Value @{ __proto__ = @{ x = 1 } } } | Should -Throw
        }

        It "throws when the serialized value exceeds 32,768 UTF-8 bytes" {
            $bigValue = @{ data = ('x' * 40000) }

            { ConvertTo-PropertyJson -Value $bigValue } | Should -Throw "*32,768*"
        }

        It "accepts a value at the size boundary" {
            $paddedValue = @{ data = ('x' * 32000) }

            { ConvertTo-PropertyJson -Value $paddedValue } | Should -Not -Throw
        }
    }
}
