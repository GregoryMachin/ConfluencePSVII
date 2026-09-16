#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "ConvertTo-IconV2" -Tag 'Unit' {
        Context "Full v2 shape with dimensions present" {
            BeforeAll {
                $json = @'
{
    "path": "/images/icons/space.png",
    "apiDownloadLink": "/wiki/download/space.png",
    "width": 48,
    "height": 48,
    "isDefault": false,
    "authorId": "712020:aaaa"
}
'@
                $script:result = ConvertTo-IconV2 -InputObject (ConvertFrom-Json -InputObject $json)
            }

            It "creates a ConfluencePS.Icon object" {
                $script:result | Should -BeOfType [ConfluencePS.Icon]
            }

            It "prefers path over apiDownloadLink" {
                $script:result.Path | Should -Be '/images/icons/space.png'
            }

            It "maps width, height, and isDefault" {
                $script:result.Width | Should -Be 48
                $script:result.Height | Should -Be 48
                $script:result.IsDefault | Should -BeFalse
            }
        }

        Context "Download-link-only v2 shape (typical Cloud v2 response)" {
            BeforeAll {
                $json = '{"apiDownloadLink": "/wiki/download/space.png"}'
                $script:result = ConvertTo-IconV2 -InputObject (ConvertFrom-Json -InputObject $json)
            }

            It "falls back to apiDownloadLink when path is absent" {
                $script:result.Path | Should -Be '/wiki/download/space.png'
            }

            It "defaults missing dimensions to zero and IsDefault to false" {
                $script:result.Width | Should -Be 0
                $script:result.Height | Should -Be 0
                $script:result.IsDefault | Should -BeFalse
            }
        }

        Context "Pipeline support" {
            It "accepts input from the pipeline and handles arrays" {
                $one = ConvertFrom-Json -InputObject '{"path": "/a.png"}'
                $two = ConvertFrom-Json -InputObject '{"path": "/b.png"}'

                $result = @($one, $two) | ConvertTo-IconV2

                @($result).Count | Should -Be 2
                $result[0].Path | Should -Be '/a.png'
                $result[1].Path | Should -Be '/b.png'
            }
        }
    }
}
