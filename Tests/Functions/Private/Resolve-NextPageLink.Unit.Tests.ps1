#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Resolve-NextPageLink" -Tag 'Unit' {
        BeforeAll {
            $script:requestUri = [Uri]'https://example.atlassian.net/wiki/rest/api/content?limit=25'
        }

        It "returns null when no next link is present anywhere" {
            $body = [PSCustomObject]@{ results = @() }

            Resolve-NextPageLink -RequestUri $requestUri -ResponseBody $body -Headers @{} |
                Should -BeNullOrEmpty
        }

        It "resolves a v1-style relative body link against _links.base" {
            $body = [PSCustomObject]@{
                _links = [PSCustomObject]@{
                    base = 'https://example.atlassian.net'
                    next = '/wiki/rest/api/content?start=25&limit=25'
                }
            }

            $result = Resolve-NextPageLink -RequestUri $requestUri -ResponseBody $body -Headers @{}

            $result.AbsoluteUri | Should -BeExactly 'https://example.atlassian.net/wiki/rest/api/content?start=25&limit=25'
        }

        It "resolves a v2-style relative body link with no _links.base against the request URI" {
            $body = [PSCustomObject]@{
                _links = [PSCustomObject]@{
                    next = '/wiki/api/v2/pages?cursor=opaque-token&limit=25'
                }
            }
            $v2Uri = [Uri]'https://example.atlassian.net/wiki/api/v2/pages?limit=25'

            $result = Resolve-NextPageLink -RequestUri $v2Uri -ResponseBody $body -Headers @{}

            $result.AbsoluteUri | Should -BeExactly 'https://example.atlassian.net/wiki/api/v2/pages?cursor=opaque-token&limit=25'
        }

        It "resolves an absolute body link as-is" {
            $body = [PSCustomObject]@{
                _links = [PSCustomObject]@{
                    next = 'https://example.atlassian.net/wiki/api/v2/pages?cursor=opaque-token'
                }
            }

            $result = Resolve-NextPageLink -RequestUri $requestUri -ResponseBody $body -Headers @{}

            $result.AbsoluteUri | Should -BeExactly 'https://example.atlassian.net/wiki/api/v2/pages?cursor=opaque-token'
        }

        It "falls back to a Link response header when the body has no next link" {
            $body = [PSCustomObject]@{ results = @() }
            $headers = @{ Link = '<https://example.atlassian.net/wiki/api/v2/pages?cursor=abc>; rel="next"' }

            $result = Resolve-NextPageLink -RequestUri $requestUri -ResponseBody $body -Headers $headers

            $result.AbsoluteUri | Should -BeExactly 'https://example.atlassian.net/wiki/api/v2/pages?cursor=abc'
        }

        It "picks the next relation out of a Link header advertising prev and next" {
            $headers = @{
                Link = '<https://example.atlassian.net/wiki/api/v2/pages?cursor=prev>; rel="prev", <https://example.atlassian.net/wiki/api/v2/pages?cursor=next>; rel="next"'
            }

            $result = Resolve-NextPageLink -RequestUri $requestUri -ResponseBody $null -Headers $headers

            $result.AbsoluteUri | Should -BeExactly 'https://example.atlassian.net/wiki/api/v2/pages?cursor=next'
        }

        It "reads a Link header supplied as multiple header line values" {
            $headers = @{
                Link = @(
                    '<https://example.atlassian.net/wiki/api/v2/pages?cursor=prev>; rel="prev"',
                    '<https://example.atlassian.net/wiki/api/v2/pages?cursor=next>; rel="next"'
                )
            }

            $result = Resolve-NextPageLink -RequestUri $requestUri -ResponseBody $null -Headers $headers

            $result.AbsoluteUri | Should -BeExactly 'https://example.atlassian.net/wiki/api/v2/pages?cursor=next'
        }

        It "falls back to a Link header on a real Invoke-WebRequest-style Dictionary" {
            # Invoke-WebRequest's own .Headers property (not a Hashtable) is a generic
            # Dictionary<string, IEnumerable<string>>, which has no public Contains(key)
            # overload -- only ContainsKey. A Hashtable-backed test headers object would
            # not have caught a regression to .Contains here.
            $headers = [System.Collections.Generic.Dictionary[string, string[]]]::new()
            $headers['Link'] = @('<https://example.atlassian.net/wiki/api/v2/pages?cursor=next>; rel="next"')

            $result = Resolve-NextPageLink -RequestUri $requestUri -ResponseBody $null -Headers $headers

            $result.AbsoluteUri | Should -BeExactly 'https://example.atlassian.net/wiki/api/v2/pages?cursor=next'
        }

        It "reads a Link header exposed through TryGetValues" {
            $headers = [PSCustomObject]@{}
            $headers | Add-Member -MemberType ScriptMethod -Name TryGetValues -Value {
                param($name, [ref]$values)
                if ($name -eq 'Link') {
                    $values.Value = @('<https://example.atlassian.net/wiki/api/v2/pages?cursor=next>; rel="next"')
                    return $true
                }
                return $false
            }

            $result = Resolve-NextPageLink -RequestUri $requestUri -ResponseBody $null -Headers $headers

            $result.AbsoluteUri | Should -BeExactly 'https://example.atlassian.net/wiki/api/v2/pages?cursor=next'
        }

        It "prefers the body next link over a Link header when both are present" {
            $body = [PSCustomObject]@{
                _links = [PSCustomObject]@{
                    base = 'https://example.atlassian.net'
                    next = '/wiki/rest/api/content?start=25'
                }
            }
            $headers = @{ Link = '<https://example.atlassian.net/wiki/api/v2/pages?cursor=next>; rel="next"' }

            $result = Resolve-NextPageLink -RequestUri $requestUri -ResponseBody $body -Headers $headers

            $result.AbsoluteUri | Should -BeExactly 'https://example.atlassian.net/wiki/rest/api/content?start=25'
        }

        It "throws when the resolved link points at a different host" {
            $body = [PSCustomObject]@{
                _links = [PSCustomObject]@{
                    base = 'https://evil.example.com'
                    next = '/wiki/rest/api/content?start=25'
                }
            }

            { Resolve-NextPageLink -RequestUri $requestUri -ResponseBody $body -Headers @{} } |
                Should -Throw "*untrusted host*"
        }

        It "throws when the resolved link downgrades scheme" {
            $body = [PSCustomObject]@{
                _links = [PSCustomObject]@{
                    next = 'http://example.atlassian.net/wiki/rest/api/content?start=25'
                }
            }

            { Resolve-NextPageLink -RequestUri $requestUri -ResponseBody $body -Headers @{} } |
                Should -Throw "*untrusted host*"
        }
    }
}
