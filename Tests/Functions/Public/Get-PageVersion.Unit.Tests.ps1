#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Get-PageVersion" -Tag 'Unit' {
        BeforeEach {
            $script:lastUri = $null
            $script:lastGetParameters = $null
        }

        Context "byList (v1)" {
            BeforeEach {
                Mock Invoke-Method -ModuleName ConfluencePSVII {
                    param([string]$Uri, [hashtable]$GetParameters)
                    $script:lastUri = $Uri
                    $script:lastGetParameters = $GetParameters
                    [ConfluencePSVII.Version]::new()
                }
            }

            It "requests the v1 version-history route" {
                $result = Get-PageVersion -ApiUri "https://example.com/wiki/rest/api" -PageID 196608

                $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/196608/version"
                $result | Should -BeOfType [ConfluencePSVII.Version]
            }
        }

        Context "byVersion (v1)" {
            BeforeEach {
                Mock Invoke-Method -ModuleName ConfluencePSVII {
                    param([string]$Uri, [hashtable]$GetParameters)
                    $script:lastUri = $Uri
                    $script:lastGetParameters = $GetParameters
                    [ConfluencePSVII.Page]::new()
                }
            }

            It "requests the page route with the version query parameter" {
                $result = Get-PageVersion -ApiUri "https://example.com/wiki/rest/api" -PageID 196608 -VersionNumber 3

                $script:lastUri | Should -Be "https://example.com/wiki/rest/api/content/196608"
                $script:lastGetParameters['version'] | Should -Be 3
                $script:lastGetParameters['expand'] | Should -Be 'version'
                $result | Should -BeOfType [ConfluencePSVII.Page]
            }

            It "expands body.storage when -IncludeBody is set" {
                $null = Get-PageVersion -ApiUri "https://example.com/wiki/rest/api" -PageID 196608 -VersionNumber 3 -IncludeBody

                $script:lastGetParameters['expand'] | Should -Be 'body.storage,version'
            }
        }

        Context "Cloud v2 routing" {
            Context "byList" {
                BeforeEach {
                    Mock Invoke-Method -ModuleName ConfluencePSVII {
                        param([Uri]$Uri)
                        $script:lastUri = $Uri.AbsoluteUri
                        ConvertFrom-Json '{"number": 3, "authorId": "712020:aaaa", "createdAt": "2023-05-24T15:11:22.331Z"}'
                    }
                }

                It "routes to the dedicated v2 versions collection" {
                    $result = Get-PageVersion -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 196608

                    $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/pages/196608/versions"
                    $result | Should -BeOfType [ConfluencePSVII.Version]
                    $result.Number | Should -Be 3
                }
            }

            Context "byVersion" {
                BeforeEach {
                    Mock Invoke-Method -ModuleName ConfluencePSVII {
                        param([Uri]$Uri, [hashtable]$GetParameters)
                        $script:lastUri = $Uri.AbsoluteUri
                        $script:lastGetParameters = $GetParameters
                        ConvertFrom-Json '{"id": "196608", "status": "current", "title": "Example", "body": {"storage": {"value": "<p>Hi</p>"}}}'
                    }
                }

                It "routes to the dedicated v2 version-by-number route" {
                    $result = Get-PageVersion -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 196608 -VersionNumber 3

                    $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/pages/196608/versions/3"
                    $result | Should -BeOfType [ConfluencePSVII.Page]
                }

                It "requests body-format=storage when -IncludeBody is set" {
                    $null = Get-PageVersion -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 196608 -VersionNumber 3 -IncludeBody

                    $script:lastGetParameters['body-format'] | Should -Be 'storage'
                }

                It "omits body-format by default" {
                    $null = Get-PageVersion -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 196608 -VersionNumber 3

                    $script:lastGetParameters.ContainsKey('body-format') | Should -BeFalse
                }
            }

            It "falls back to the v1 route when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                Mock Invoke-Method -ModuleName ConfluencePSVII {
                    param([string]$Uri)
                    $script:lastUri = $Uri
                    [ConfluencePSVII.Version]::new()
                }

                $null = Get-PageVersion -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -PageID 196608

                $script:lastUri | Should -Be "https://example.atlassian.net/wiki/rest/api/content/196608/version"
            }
        }
    }
}
