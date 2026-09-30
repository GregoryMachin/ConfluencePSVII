#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "ConvertTo-UserV2" -Tag 'Unit' {
        It "wraps an account ID in UserKey and leaves other properties unset" {
            $result = ConvertTo-UserV2 -AccountId '712020:aaaa-bbbb-cccc'

            $result | Should -BeOfType [ConfluencePSVII.User]
            $result.UserKey | Should -Be '712020:aaaa-bbbb-cccc'
            $result.UserName | Should -BeNullOrEmpty
            $result.DisplayName | Should -BeNullOrEmpty
            $result.ProfilePicture | Should -BeNullOrEmpty
        }

        It "returns null for a null or empty account ID" {
            ConvertTo-UserV2 -AccountId $null | Should -BeNullOrEmpty
            ConvertTo-UserV2 -AccountId '' | Should -BeNullOrEmpty
        }

        It "accepts input from the pipeline" {
            $result = '712020:pipeline' | ConvertTo-UserV2

            $result.UserKey | Should -Be '712020:pipeline'
        }

        It "handles array input" {
            $result = @('712020:one', '712020:two') | ConvertTo-UserV2

            @($result).Count | Should -Be 2
            $result[0].UserKey | Should -Be '712020:one'
            $result[1].UserKey | Should -Be '712020:two'
        }
    }
}
