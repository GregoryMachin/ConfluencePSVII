#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Get-ChildPage" -Tag 'Unit' {
        BeforeAll {
            function New-TestPage {
                param(
                    [UInt64]$ID
                )

                $page = [ConfluencePSVII.Page]::new()
                $page.ID = $ID
                $page
            }
        }

        It "uses descendant endpoint directly for recursive queries" {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                New-TestPage -ID 11
            }

            $null = Get-ChildPage -ApiUri "https://example.com/wiki/rest/api" -PageID 10 -Recurse -Skip 2 -First 3 -IncludeTotalCount

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It -ParameterFilter {
                $Uri -eq "https://example.com/wiki/rest/api/content/10/descendant/page" -and
                $Skip -eq 2 -and
                $First -eq 3 -and
                $IncludeTotalCount
            }
            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It -ParameterFilter {
                $Uri -like "https://example.com/wiki/rest/api/content/*/child/page"
            }
        }

        It "falls back to iterative child traversal and applies paging globally when descendant endpoint fails" {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                param(
                    [string]$Uri
                )

                switch ($Uri) {
                    "https://example.com/wiki/rest/api/content/10/descendant/page" {
                        throw [System.ArgumentException]::new("Invalid Server Response")
                    }
                    "https://example.com/wiki/rest/api/content/10/child/page" {
                        @((New-TestPage -ID 11), (New-TestPage -ID 12))
                    }
                    "https://example.com/wiki/rest/api/content/11/child/page" {
                        @(New-TestPage -ID 13)
                    }
                    "https://example.com/wiki/rest/api/content/12/child/page" {
                        @()
                    }
                    "https://example.com/wiki/rest/api/content/13/child/page" {
                        @()
                    }
                    default {
                        throw "Unexpected URI: $Uri"
                    }
                }
            }

            $result = @(Get-ChildPage -ApiUri "https://example.com/wiki/rest/api" -PageID 10 -Recurse -Skip 1 -First 2)

            $result.ID | Should -Be @(12, 13)
            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It -ParameterFilter {
                $Uri -eq "https://example.com/wiki/rest/api/content/10/descendant/page"
            }
            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 4 -Scope It -ParameterFilter {
                $Uri -like "https://example.com/wiki/rest/api/content/*/child/page" -and
                (-not $PSBoundParameters.ContainsKey("Skip")) -and
                (-not $PSBoundParameters.ContainsKey("First")) -and
                (-not $PSBoundParameters.ContainsKey("IncludeTotalCount"))
            }
        }

        It "rethrows non-recoverable descendant endpoint errors" {
            Mock Invoke-Method -ModuleName ConfluencePSVII {
                throw [System.ArgumentException]::new("Not a recoverable error")
            }

            {
                Get-ChildPage -ApiUri "https://example.com/wiki/rest/api" -PageID 10 -Recurse -ErrorAction Stop
            } | Should -Throw "Not a recoverable error"

            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It -ParameterFilter {
                $Uri -eq "https://example.com/wiki/rest/api/content/10/descendant/page"
            }
            Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It -ParameterFilter {
                $Uri -like "https://example.com/wiki/rest/api/content/*/child/page"
            }
        }

        Context "Cloud v2 routing" {
            BeforeAll {
                function New-TestPageV2Json {
                    param([UInt64]$ID)

                    '{{"id": "{0}"}}' -f $ID
                }
            }

            It "uses the v2 direct-children route for non-recursive queries" {
                Mock Invoke-Method -ModuleName ConfluencePSVII {
                    ConvertFrom-Json (New-TestPageV2Json -ID 11)
                }

                $result = Get-ChildPage -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 10

                $result | Should -BeOfType [ConfluencePSVII.Page]
                $result.ID | Should -Be 11
                Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Uri -eq "https://example.atlassian.net/wiki/api/v2/pages/10/direct-children"
                }
            }

            It "uses the v2 descendants route directly for recursive queries" {
                Mock Invoke-Method -ModuleName ConfluencePSVII {
                    ConvertFrom-Json (New-TestPageV2Json -ID 11)
                }

                $null = Get-ChildPage -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 10 -Recurse -Skip 2 -First 3 -IncludeTotalCount

                Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Uri -eq "https://example.atlassian.net/wiki/api/v2/pages/10/descendants" -and
                    $Skip -eq 2 -and
                    $First -eq 3 -and
                    $IncludeTotalCount
                }
                Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It -ParameterFilter {
                    $Uri -like "*/direct-children"
                }
            }

            It "falls back to iterative v2 direct-children traversal when descendants fails" {
                Mock Invoke-Method -ModuleName ConfluencePSVII {
                    param([string]$Uri)

                    switch ($Uri) {
                        "https://example.atlassian.net/wiki/api/v2/pages/10/descendants" {
                            throw [System.ArgumentException]::new("Invalid Server Response")
                        }
                        "https://example.atlassian.net/wiki/api/v2/pages/10/direct-children" {
                            @((ConvertFrom-Json (New-TestPageV2Json -ID 11)), (ConvertFrom-Json (New-TestPageV2Json -ID 12)))
                        }
                        "https://example.atlassian.net/wiki/api/v2/pages/11/direct-children" {
                            @(ConvertFrom-Json (New-TestPageV2Json -ID 13))
                        }
                        "https://example.atlassian.net/wiki/api/v2/pages/12/direct-children" {
                            @()
                        }
                        "https://example.atlassian.net/wiki/api/v2/pages/13/direct-children" {
                            @()
                        }
                        default {
                            throw "Unexpected URI: $Uri"
                        }
                    }
                }

                $result = @(Get-ChildPage -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -DeploymentType Cloud -PageID 10 -Recurse -Skip 1 -First 2)

                $result.ID | Should -Be @(12, 13)
            }

            It "falls back to the v1 traversal when -BaseUri is not supplied, even with -DeploymentType Cloud" {
                Mock Invoke-Method -ModuleName ConfluencePSVII {
                    $page = [ConfluencePSVII.Page]::new()
                    $page.ID = 11
                    $page
                }

                $null = Get-ChildPage -ApiUri "https://example.atlassian.net/wiki/rest/api" -DeploymentType Cloud -PageID 10

                Should -Invoke -CommandName Invoke-Method -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Uri -eq "https://example.atlassian.net/wiki/rest/api/content/10/child/page"
                }
            }
        }
    }
}
