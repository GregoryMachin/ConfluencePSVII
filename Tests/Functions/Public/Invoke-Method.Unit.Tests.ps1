#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Invoke-Method" -Tag 'Unit' {
        BeforeAll {
            if (-not ("System.Net.Http.HttpResponseMessage" -as [Type])) {
                Add-Type -AssemblyName System.Net.Http
            }

            if (-not ("ConfluencePSVII.Tests.FakeHttpException" -as [Type])) {
                Add-Type -TypeDefinition @"
namespace ConfluencePSVII.Tests {
    using System;

    public class FakeHttpException : Exception {
        public object Response { get; private set; }

        public FakeHttpException(string message, object response) : base(message) {
            this.Response = response;
        }
    }
}
"@
            }

            function script:New-FakeWebResponse {
                param(
                    [int]$StatusCode = 200,
                    [string]$Json = '{"results":[]}',
                    [hashtable]$Headers = @{}
                )

                $statusCodeEnum = [System.Enum]::ToObject([System.Net.HttpStatusCode], $StatusCode)

                [PSCustomObject]@{
                    StatusCode       = $statusCodeEnum
                    Content          = $Json
                    RawContentStream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($Json))
                    Headers          = $Headers
                }
            }

            Mock Set-TlsLevel -ModuleName ConfluencePSVII {}
            Mock Test-Captcha -ModuleName ConfluencePSVII {}
            Mock Start-Sleep -ModuleName ConfluencePSVII {}
        }

        BeforeEach {
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                New-FakeWebResponse -StatusCode 200 -Json '{"results":[]}'
            }
        }

        It "URL-encodes GET parameters before invoking the request" {
            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -GetParameters @{
                "sp ace" = "hello/world & me"
            } -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -ParameterFilter {
                $Uri.Query -match 'sp(\+|%20)ace=hello%2fworld(\+|%20)%26(\+|%20)me'
            } -Exactly -Times 1 -Scope It
        }

        It "forwards default TimeoutSec to Invoke-WebRequest" {
            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -ParameterFilter {
                $TimeoutSec -eq 100
            } -Exactly -Times 1 -Scope It
        }

        It "forwards explicit TimeoutSec to Invoke-WebRequest" {
            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -TimeoutSec 30 -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -ParameterFilter {
                $TimeoutSec -eq 30
            } -Exactly -Times 1 -Scope It
        }

        It "forwards PersonalAccessToken to Invoke-WebRequest" {
            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -PersonalAccessToken "token-value" -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -ParameterFilter {
                $PersonalAccessToken -eq "token-value"
            } -Exactly -Times 1 -Scope It
        }

        It "sends explicit authorization for Confluence Cloud attachment web downloads" {
            if (-not (Get-Command -Name 'Microsoft.PowerShell.Utility\Invoke-WebRequest').Parameters.ContainsKey('PreserveAuthorizationOnRedirect')) {
                Set-ItResult -Skipped -Because "PreserveAuthorizationOnRedirect is unavailable in this PowerShell version."
                return
            }

            $securePassword = ConvertTo-SecureString -AsPlainText -Force -String "password"
            $credential = [pscredential]::new("user", $securePassword)

            $null = Invoke-Method -Uri "https://tenant.atlassian.net/wiki/download/attachments/123/Test.txt" -Credential $credential -OutFile "Test.txt" -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -ParameterFilter {
                (-not $PSBoundParameters.ContainsKey('Credential')) -and
                $Headers.Authorization -eq 'Basic dXNlcjpwYXNzd29yZA=='
            } -Exactly -Times 1 -Scope It
        }

        It "sends explicit authorization for Confluence Cloud attachment REST downloads" {
            if (-not (Get-Command -Name 'Microsoft.PowerShell.Utility\Invoke-WebRequest').Parameters.ContainsKey('PreserveAuthorizationOnRedirect')) {
                Set-ItResult -Skipped -Because "PreserveAuthorizationOnRedirect is unavailable in this PowerShell version."
                return
            }

            $securePassword = ConvertTo-SecureString -AsPlainText -Force -String "password"
            $credential = [pscredential]::new("user", $securePassword)

            $null = Invoke-Method -Uri "https://tenant.atlassian.net/wiki/rest/api/content/123/child/attachment/456/download" -Credential $credential -OutFile "Test.txt" -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -ParameterFilter {
                (-not $PSBoundParameters.ContainsKey('Credential')) -and
                $Headers.Authorization -eq 'Basic dXNlcjpwYXNzd29yZA=='
            } -Exactly -Times 1 -Scope It
        }

        It "sends explicit authorization for Confluence Cloud attachment REST downloads on custom domains" {
            if (-not (Get-Command -Name 'Microsoft.PowerShell.Utility\Invoke-WebRequest').Parameters.ContainsKey('PreserveAuthorizationOnRedirect')) {
                Set-ItResult -Skipped -Because "PreserveAuthorizationOnRedirect is unavailable in this PowerShell version."
                return
            }

            $securePassword = ConvertTo-SecureString -AsPlainText -Force -String "password"
            $credential = [pscredential]::new("user", $securePassword)

            $null = Invoke-Method -Uri "https://docs.example.com/wiki/rest/api/content/123/child/attachment/456/download" -Credential $credential -OutFile "Test.txt" -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -ParameterFilter {
                (-not $PSBoundParameters.ContainsKey('Credential')) -and
                $Headers.Authorization -eq 'Basic dXNlcjpwYXNzd29yZA=='
            } -Exactly -Times 1 -Scope It
        }

        It "does not send explicit authorization on non-Cloud file downloads" {
            $securePassword = ConvertTo-SecureString -AsPlainText -Force -String "password"
            $credential = [pscredential]::new("user", $securePassword)

            $null = Invoke-Method -Uri "http://localhost:1990/confluence/download/attachments/123/Test.txt" -Credential $credential -OutFile "Test.txt" -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -ParameterFilter {
                $Credential -eq $credential -and
                (-not $Headers.ContainsKey('Authorization'))
            } -Exactly -Times 1 -Scope It
        }

        It "supports PersonalAccessToken in the private Invoke-WebRequest wrapper" {
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                Set-ItResult -Skipped -Because "PowerShell 5.1 wrapper handles PersonalAccessToken separately."
                return
            }

            (Get-Command -Name Invoke-WebRequest).Parameters.Keys | Should -Contain "PersonalAccessToken"
        }

        It "omits TimeoutSec from Invoke-WebRequest when TimeoutSec is 0" {
            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -TimeoutSec 0 -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -ParameterFilter {
                -not $PSBoundParameters.ContainsKey("TimeoutSec")
            } -Exactly -Times 1 -Scope It
        }

        It "allows unencrypted authentication only when explicitly enabled for localhost" {
            if (
                ($PSVersionTable.PSVersion.Major -lt 6) -or
                (-not (Get-Command Invoke-WebRequest).Parameters.ContainsKey("AllowUnencryptedAuthentication"))
            ) {
                Set-ItResult -Skipped -Because "AllowUnencryptedAuthentication is unavailable in this PowerShell version."
                return
            }

            $securePassword = ConvertTo-SecureString -AsPlainText -Force -String "password"
            $credential = [pscredential]::new("user", $securePassword)

            $originalFlag = $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH
            $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = "true"

            try {
                $null = Invoke-Method -Uri "http://localhost/wiki/rest/api/content" -Credential $credential -ErrorAction Stop

                Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -ParameterFilter {
                    $AllowUnencryptedAuthentication
                } -Exactly -Times 1 -Scope It
            }
            finally {
                $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = $originalFlag
            }
        }

        It "does not set unencrypted authentication when explicit opt-in is missing" {
            if (
                ($PSVersionTable.PSVersion.Major -lt 6) -or
                (-not (Get-Command Invoke-WebRequest).Parameters.ContainsKey("AllowUnencryptedAuthentication"))
            ) {
                Set-ItResult -Skipped -Because "AllowUnencryptedAuthentication is unavailable in this PowerShell version."
                return
            }

            $securePassword = ConvertTo-SecureString -AsPlainText -Force -String "password"
            $credential = [pscredential]::new("user", $securePassword)
            $originalFlag = $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH
            $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = $null

            try {
                $null = Invoke-Method -Uri "http://localhost/wiki/rest/api/content" -Credential $credential -ErrorAction Stop

                Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -ParameterFilter {
                    -not $AllowUnencryptedAuthentication
                } -Exactly -Times 1 -Scope It
            }
            finally {
                $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = $originalFlag
            }
        }

        It "does not set unencrypted authentication for non-local HTTP hosts" {
            if (
                ($PSVersionTable.PSVersion.Major -lt 6) -or
                (-not (Get-Command Invoke-WebRequest).Parameters.ContainsKey("AllowUnencryptedAuthentication"))
            ) {
                Set-ItResult -Skipped -Because "AllowUnencryptedAuthentication is unavailable in this PowerShell version."
                return
            }

            $securePassword = ConvertTo-SecureString -AsPlainText -Force -String "password"
            $credential = [pscredential]::new("user", $securePassword)
            $originalFlag = $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH
            $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = "true"

            try {
                $null = Invoke-Method -Uri "http://example.com/wiki/rest/api/content" -Credential $credential -ErrorAction Stop

                Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -ParameterFilter {
                    -not $AllowUnencryptedAuthentication
                } -Exactly -Times 1 -Scope It
            }
            finally {
                $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = $originalFlag
            }
        }

        It "does not set unencrypted authentication for HTTPS requests" {
            if (
                ($PSVersionTable.PSVersion.Major -lt 6) -or
                (-not (Get-Command Invoke-WebRequest).Parameters.ContainsKey("AllowUnencryptedAuthentication"))
            ) {
                Set-ItResult -Skipped -Because "AllowUnencryptedAuthentication is unavailable in this PowerShell version."
                return
            }

            $securePassword = ConvertTo-SecureString -AsPlainText -Force -String "password"
            $credential = [pscredential]::new("user", $securePassword)
            $originalFlag = $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH
            $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = "true"

            try {
                $null = Invoke-Method -Uri "https://localhost/wiki/rest/api/content" -Credential $credential -ErrorAction Stop

                Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -ParameterFilter {
                    -not $AllowUnencryptedAuthentication
                } -Exactly -Times 1 -Scope It
            }
            finally {
                $env:CONFLUENCE_ALLOW_UNENCRYPTED_AUTH = $originalFlag
            }
        }

        It "handles success payloads with duplicate JSON key casing" {
            if (-not (Get-Command ConvertFrom-Json).Parameters.ContainsKey("AsHashtable")) {
                Set-ItResult -Skipped -Because "ConvertFrom-Json -AsHashtable is unavailable in this PowerShell version."
                return
            }

            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                New-FakeWebResponse -StatusCode 200 -Json '{"results":[{"id":1,"subType":"page","subtype":"page"}]}'
            }

            { $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop } | Should -Not -Throw

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It
        }

        It "retries once on HTTP 429 and continues successfully" {
            $script:invokeCount = 0
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                if ($script:invokeCount -eq 0) {
                    $script:invokeCount++
                    New-FakeWebResponse -StatusCode 429 -Json '{"message":"rate limited"}' -Headers @{ "Retry-After" = "0" }
                }
                else {
                    New-FakeWebResponse -StatusCode 200 -Json '{"results":[]}'
                }
            }

            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -Exactly -Times 2 -Scope It
            Should -Invoke -CommandName Start-Sleep -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It
        }

        It "honors Retry-After without capping or downward jitter" {
            $script:invokeCount = 0
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                if ($script:invokeCount -eq 0) {
                    $script:invokeCount++
                    New-FakeWebResponse -StatusCode 429 -Json '{"message":"rate limited"}' -Headers @{ "Retry-After" = "120" }
                }
                else {
                    New-FakeWebResponse -StatusCode 200 -Json '{"results":[]}'
                }
            }

            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop

            Should -Invoke -CommandName Start-Sleep -ModuleName ConfluencePSVII -ParameterFilter {
                [Math]::Abs([double]$Seconds - 120.0) -lt 0.001
            } -Exactly -Times 1 -Scope It
        }

        It "does not retry non-idempotent methods by default" {
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                New-FakeWebResponse -StatusCode 429 -Json '{"message":"rate limited"}' -Headers @{ "Retry-After" = "1" }
            }

            { Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -Method Post -Body '{}' -ErrorAction Stop } | Should -Throw

            Should -Invoke -CommandName Invoke-WebRequest -ModuleName ConfluencePSVII -Exactly -Times 1 -Scope It
            Should -Invoke -CommandName Start-Sleep -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It
        }

        It "propagates TimeoutSec to pagination follow-up calls" {
            $script:timeouts = @()
            $script:requestUris = @()
            $script:invokeCount = 0
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                param($Uri, $TimeoutSec)

                $script:timeouts += if ($null -ne $TimeoutSec) { [int]$TimeoutSec } else { $null }
                $script:requestUris += $Uri.AbsoluteUri

                if ($script:invokeCount -eq 0) {
                    $script:invokeCount++
                    return New-FakeWebResponse -StatusCode 200 -Json '{"results":[{"id":1}],"_links":{"base":"https://example.com","next":"/wiki/rest/api/content?start=25"}}'
                }

                New-FakeWebResponse -StatusCode 200 -Json '{"results":[{"id":2}]}'
            }

            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -TimeoutSec 33 -ErrorAction Stop

            $script:timeouts | Should -HaveCount 2
            $script:timeouts[0] | Should -Be 33
            $script:timeouts[1] | Should -Be 33
            $script:requestUris[1] | Should -Be "https://example.com/wiki/rest/api/content?start=25"
        }

        It "preserves GET parameters when following pagination links" {
            $script:requestUris = @()
            $script:invokeCount = 0
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                param($Uri)

                $script:requestUris += $Uri.AbsoluteUri

                if ($script:invokeCount -eq 0) {
                    $script:invokeCount++
                    return New-FakeWebResponse -StatusCode 200 -Json '{"results":[{"id":1}],"_links":{"base":"https://example.com","next":"/wiki/rest/api/content?limit=20&start=20"}}'
                }

                if ($script:invokeCount -eq 1) {
                    $script:invokeCount++
                    return New-FakeWebResponse -StatusCode 200 -Json '{"results":[{"id":2}],"_links":{"base":"https://example.com","next":"/wiki/rest/api/content?limit=20&start=40"}}'
                }

                New-FakeWebResponse -StatusCode 200 -Json '{"results":[{"id":3}]}'
            }

            $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -GetParameters @{
                spaceKey = "Foo"
                title    = "my Page"
            } -ErrorAction Stop

            $script:requestUris | Should -HaveCount 3
            foreach ($nextUri in @([uri]$script:requestUris[1], [uri]$script:requestUris[2])) {
                $nextQueryParameters = [System.Web.HttpUtility]::ParseQueryString($nextUri.Query)
                $nextQueryParameters["spaceKey"] | Should -Be "Foo"
                $nextQueryParameters["title"] | Should -Be "my Page"
                $nextQueryParameters["limit"] | Should -Be "20"
            }
            ([System.Web.HttpUtility]::ParseQueryString(([uri]$script:requestUris[1]).Query))["start"] | Should -Be "20"
            ([System.Web.HttpUtility]::ParseQueryString(([uri]$script:requestUris[2]).Query))["start"] | Should -Be "40"
        }

        It "refuses pagination links that leave the original trusted host" {
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                New-FakeWebResponse -StatusCode 200 -Json '{"results":[{"id":1}],"_links":{"base":"https://evil.example.com","next":"/wiki/rest/api/content?start=25"}}'
            }

            { Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop } | Should -Throw "*untrusted host*"
        }

        It "follows a v2-style Link response header when the body has no next link" {
            $script:requestUris = @()
            $script:invokeCount = 0
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                param($Uri)

                $script:requestUris += $Uri.AbsoluteUri

                if ($script:invokeCount -eq 0) {
                    $script:invokeCount++
                    return New-FakeWebResponse -StatusCode 200 -Json '{"results":[{"id":1}]}' -Headers @{
                        Link = '<https://example.com/wiki/api/v2/pages?cursor=abc&limit=25>; rel="next"'
                    }
                }

                New-FakeWebResponse -StatusCode 200 -Json '{"results":[{"id":2}]}'
            }

            $result = Invoke-Method -Uri "https://example.com/wiki/api/v2/pages?limit=25" -ErrorAction Stop

            $result | Should -HaveCount 2
            $script:requestUris | Should -HaveCount 2
            $script:requestUris[1] | Should -Be "https://example.com/wiki/api/v2/pages?cursor=abc&limit=25"
        }

        It "stops instead of looping forever when the same link is returned again" {
            $script:invokeCount = 0
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                $script:invokeCount++
                New-FakeWebResponse -StatusCode 200 -Json '{"results":[{"id":1}],"_links":{"base":"https://example.com","next":"/wiki/rest/api/content?start=25"}}'
            }
            Mock Write-Warning -ModuleName ConfluencePSVII {}

            $result = Invoke-Method -Uri "https://example.com/wiki/rest/api/content?start=25" -ErrorAction Stop

            $result | Should -HaveCount 1
            $script:invokeCount | Should -Be 1
            Should -Invoke -CommandName Write-Warning -ModuleName ConfluencePSVII -ParameterFilter {
                $Message -match "same pagination link again"
            } -Exactly -Times 1 -Scope It
        }

        It "stops pagination once a page returns no results, even if the server still advertises a next link" {
            # Confluence Server/Data Center can keep sending a `_links.next` after a
            # collection is genuinely exhausted (a real observed quirk); an empty
            # page must end pagination regardless of what the server advertises,
            # or every follow-up page being empty-but-linked would recurse forever.
            $script:invokeCount = 0
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                $script:invokeCount++
                if ($script:invokeCount -eq 1) {
                    return New-FakeWebResponse -StatusCode 200 -Json '{"results":[{"id":1}],"_links":{"base":"https://example.com","next":"/wiki/rest/api/content?start=1"}}'
                }
                New-FakeWebResponse -StatusCode 200 -Json '{"results":[],"_links":{"base":"https://example.com","next":"/wiki/rest/api/content?start=2"}}'
            }

            $result = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop

            @($result).Count | Should -Be 1
            $script:invokeCount | Should -Be 2
        }

        It "throws a clear error instead of looping indefinitely when pagination never terminates" {
            $script:invokeCount = 0
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                $script:invokeCount++
                New-FakeWebResponse -StatusCode 200 -Json (
                    '{{"results":[{{"id":{0}}}],"_links":{{"base":"https://example.com","next":"/wiki/rest/api/content?start={0}"}}}}' -f $script:invokeCount
                )
            }

            # Start one page short of the cap (an internal, DontShow-only parameter) so the
            # test reaches the boundary in a couple of iterations instead of thousands.
            { Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -PageDepth 9999 -ErrorAction Stop } | Should -Throw "*exceeded the maximum*"

            $script:invokeCount | Should -Be 2
        }

        It "stops following pagination links once -First is satisfied" {
            $script:invokeCount = 0
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                $script:invokeCount++
                New-FakeWebResponse -StatusCode 200 -Json (
                    '{{"results":[{{"id":{0}}},{{"id":{1}}}],"_links":{{"base":"https://example.com","next":"/wiki/rest/api/content?start={2}"}}}}' -f
                    (($script:invokeCount - 1) * 2 + 1), (($script:invokeCount - 1) * 2 + 2), ($script:invokeCount * 2)
                )
            }

            $result = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -First 3 -ErrorAction Stop

            @($result).Count | Should -Be 3
            $script:invokeCount | Should -Be 2
        }

        It "does not fetch a second page when -First is satisfied by the first page" {
            $script:invokeCount = 0
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                $script:invokeCount++
                New-FakeWebResponse -StatusCode 200 -Json '{"results":[{"id":1},{"id":2},{"id":3}],"_links":{"base":"https://example.com","next":"/wiki/rest/api/content?start=3"}}'
            }

            $result = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -First 2 -ErrorAction Stop

            @($result).Count | Should -Be 2
            $script:invokeCount | Should -Be 1
        }

        It "surfaces JSON errorMessages from HTTP error responses" {
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                New-FakeWebResponse -StatusCode 400 -Json '{"errorMessages":["Alpha issue","Beta issue"]}'
            }

            $thrown = $null
            try {
                $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.ErrorDetails | Should -Not -BeNullOrEmpty
            $thrown.ErrorDetails.Message | Should -Match "Alpha issue"
        }

        It "surfaces JSON errors object-map messages from HTTP error responses" {
            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                New-FakeWebResponse -StatusCode 400 -Json '{"errors":{"title":"Title invalid","space":"Space denied"}}'
            }

            $thrown = $null
            try {
                $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.ErrorDetails | Should -Not -BeNullOrEmpty
            $thrown.ErrorDetails.Message | Should -Match "Title invalid"
            $thrown.ErrorDetails.Message | Should -Match "Space denied"
        }

        It "reads HttpResponseMessage content when request throws" {
            $httpResponse = [System.Net.Http.HttpResponseMessage]::new([System.Net.HttpStatusCode]::BadRequest)
            $httpResponse.Content = [System.Net.Http.StringContent]::new(
                '{"errors":{"field":"Field problem from response content"}}',
                [System.Text.Encoding]::UTF8,
                "application/json"
            )

            Mock Invoke-WebRequest -ModuleName ConfluencePSVII {
                throw [ConfluencePSVII.Tests.FakeHttpException]::new("request failed", $httpResponse)
            }

            $thrown = $null
            try {
                $null = Invoke-Method -Uri "https://example.com/wiki/rest/api/content" -ErrorAction Stop
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.ErrorDetails | Should -Not -BeNullOrEmpty
            $thrown.ErrorDetails.Message | Should -Match "Field problem from response content"
        }
    }
}
