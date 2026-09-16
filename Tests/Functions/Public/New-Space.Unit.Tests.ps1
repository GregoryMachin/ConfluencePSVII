#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "New-Space" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePS {
                param([Uri]$Uri, [string]$Body)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                [ConfluencePS.Space]::new()
            }
        }

        It "uses the v1 space route by default" {
            $null = New-Space -ApiUri "https://example.com/wiki/rest/api" -SpaceKey "TEST" -Name "Test Space" -Description "A space" -Confirm:$false

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/space"
            $script:lastBody.key | Should -Be "TEST"
            $script:lastBody.description.plain.value | Should -Be "A space"
        }

        Context "Cloud v2 routing" {
            It "routes to the v2 spaces route and sends the flat body shape" {
                $result = New-Space -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -SpaceKey "TEST" -Name "Test Space" -Description "A space" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/spaces"
                $script:lastBody.key | Should -Be "TEST"
                $script:lastBody.name | Should -Be "Test Space"
                $script:lastBody.description.representation | Should -Be 'plain'
                $script:lastBody.description.value | Should -Be "A space"
                $result | Should -BeOfType [ConfluencePS.Space]
            }

            It "omits the description field when no description is supplied" {
                $null = New-Space -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -SpaceKey "TEST" -Name "Test Space" -Confirm:$false

                $script:lastBody.PSObject.Properties.Name | Should -Not -Contain 'description'
            }

            It "accepts a Space object through -InputObject" {
                $space = [ConfluencePS.Space]@{ Key = "OBJ"; Name = "Object Space"; Description = "From object" }

                $null = New-Space -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -InputObject $space -Confirm:$false

                $script:lastBody.key | Should -Be "OBJ"
                $script:lastBody.name | Should -Be "Object Space"
                $script:lastBody.description.value | Should -Be "From object"
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = New-Space -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -SpaceKey "TEST" -Name "Test Space" -Confirm:$false

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/space"
            }
        }
    }
}
