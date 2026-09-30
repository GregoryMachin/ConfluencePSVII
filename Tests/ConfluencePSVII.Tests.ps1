#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

Describe "General project validation" -Tag Unit {
    BeforeAll {
        Remove-Module ConfluencePSVII -ErrorAction SilentlyContinue

        $script:manifest = Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop -WarningAction SilentlyContinue
    }
    AfterEach {
        Remove-Module ConfluencePSVII -ErrorAction SilentlyContinue
    }

    It "passes Test-ModuleManifest" {
        { Test-ModuleManifest -Path $moduleToTest -ErrorAction Stop } | Should -Not -Throw
    }

    It "module 'ConfluencePSVII' can import cleanly" {
        { Import-Module $moduleToTest } | Should -Not -Throw
    }

    It "module 'ConfluencePSVII' exports functions" {
        Import-Module $moduleToTest

        (Get-Command -Module ConfluencePSVII -CommandType Function | Measure-Object).Count | Should -BeGreaterThan 0
    }

    It "module uses the correct root module" {
        $manifest.RootModule | Should -Be 'ConfluencePSVII.psm1'
    }

    It "module uses the correct guid" {
        $manifest.Guid | Should -Be '2eaf222c-8c98-46f6-97ac-fde11880ec6f'
    }

    It "module uses a valid version" {
        $manifest.Version | Should -Not -BeNullOrEmpty
        [Version]($manifest.Version) | Should -BeOfType [Version]
    }

    It "module is imported with default prefix" {
        $prefix = $manifest.DefaultCommandPrefix

        Import-Module $moduleToTest -Force -ErrorAction Stop
        (Get-Command -Module ConfluencePSVII -CommandType Function).Name | ForEach-Object {
            $_ | Should -Match "\-$prefix"
        }
    }

    It "module is imported with custom prefix" {
        $prefix = "Wiki"

        Import-Module $moduleToTest -Prefix $prefix -Force -ErrorAction Stop
        (Get-Command -Module ConfluencePSVII -CommandType Function).Name | ForEach-Object {
            $_ | Should -Match "\-$prefix"
        }
    }
}
