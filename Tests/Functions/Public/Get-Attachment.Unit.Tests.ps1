#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Get-Attachment" -Tag 'Unit' {
        It "uses the v1 attachment route by default" {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param([Uri]$Uri, [hashtable]$GetParameters)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastGetParameters = $GetParameters
                [ConfluencePSVII.Attachment]::new()
            }

            $null = Get-Attachment -ApiUri "https://example.com/wiki/rest/api" -PageID 100

            $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/100/child/attachment"
            $script:lastGetParameters['expand'] | Should -Be 'version'
        }

        Context "Cloud v2 routing" {
            BeforeEach {
                Mock Invoke-Method -ModuleName ConfluencePSVII {
                    param([Uri]$Uri, [hashtable]$GetParameters)
                    $script:lastUri = $Uri.AbsoluteUri
                    $script:lastGetParameters = $GetParameters
                    ConvertFrom-Json '{"id": "att123", "title": "file.png", "pageId": "100"}'
                }
            }

            It "routes to the v2 attachments route when -BaseUri and -DeploymentType Cloud are supplied" {
                $result = Get-Attachment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 100

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/pages/100/attachments"
                $result | Should -BeOfType [ConfluencePSVII.Attachment]
                $result.PageID | Should -Be 100
            }

            It "does not request the v1-only expand parameter on the v2 route" {
                $null = Get-Attachment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 100

                $script:lastGetParameters.ContainsKey('expand') | Should -BeFalse
            }

            It "still applies -FileNameFilter and -MediaTypeFilter on the v2 route" {
                $null = Get-Attachment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 100 -FileNameFilter "diagram.png" -MediaTypeFilter "image/png"

                $script:lastGetParameters['filename'] | Should -Be 'diagram.png'
                $script:lastGetParameters['mediaType'] | Should -Be 'image/png'
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                $null = Get-Attachment -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -PageID 100

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/100/child/attachment"
            }

            It "uses the v1 route for Data Center regardless of -BaseUri" {
                $null = Get-Attachment -ApiUri "https://dc.example.com/rest/api" -BaseUri "https://dc.example.com" -DeploymentType DataCenter -PageID 100

                $script:lastUri | Should -Be "https://dc.example.com/rest/api/content/100/child/attachment"
            }
        }
    }
}
