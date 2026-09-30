#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "Test-ServerResponse" -Tag 'Unit' {
        BeforeAll {
            if (-not ("System.Net.Http.HttpResponseMessage" -as [Type])) {
                Add-Type -AssemblyName System.Net.Http
            }

            Mock Start-Sleep -ModuleName ConfluencePSVII {}
        }

        BeforeEach {
            Mock Get-Random -ModuleName ConfluencePSVII { 1.0 }
        }

        It "uses Retry-After HTTP-date as minimum retry delay" {
            Mock Get-Date -ModuleName ConfluencePSVII { [DateTimeOffset]"2026-01-01T00:00:00Z" }
            $response = [PSCustomObject]@{
                StatusCode = 429
                Headers    = @{ "Retry-After" = "Thu, 01 Jan 2026 00:02:00 GMT" }
            }

            $result = Test-ServerResponse -InputObject $response -Method Get -RetryCount 0 -MaxRetries 3

            $result | Should -BeTrue
            Should -Invoke -CommandName Start-Sleep -ModuleName ConfluencePSVII -ParameterFilter {
                [Math]::Abs([double]$Seconds - 120.0) -lt 0.001
            } -Exactly -Times 1 -Scope It
        }

        It "uses Retry-After from a real Invoke-WebRequest-style Dictionary" {
            # Invoke-WebRequest's own .Headers property (not a Hashtable) is a generic
            # Dictionary<string, IEnumerable<string>>, which has no public Contains(key)
            # overload -- only ContainsKey. A Hashtable-backed test headers object would
            # not have caught a regression to .Contains here.
            Mock Get-Date -ModuleName ConfluencePSVII { [DateTimeOffset]"2026-01-01T00:00:00Z" }
            $headers = [System.Collections.Generic.Dictionary[string, string[]]]::new()
            $headers['Retry-After'] = @('Thu, 01 Jan 2026 00:02:00 GMT')
            $response = [PSCustomObject]@{
                StatusCode = 429
                Headers    = $headers
            }

            $result = Test-ServerResponse -InputObject $response -Method Get -RetryCount 0 -MaxRetries 3

            $result | Should -BeTrue
            Should -Invoke -CommandName Start-Sleep -ModuleName ConfluencePSVII -ParameterFilter {
                [Math]::Abs([double]$Seconds - 120.0) -lt 0.001
            } -Exactly -Times 1 -Scope It
        }

        It "uses Retry-After from HttpResponseHeaders RetryAfter property" {
            $response = [System.Net.Http.HttpResponseMessage]::new(
                [System.Enum]::ToObject([System.Net.HttpStatusCode], 429)
            )
            $response.Headers.RetryAfter = [System.Net.Http.Headers.RetryConditionHeaderValue]::new([TimeSpan]::FromSeconds(90))

            $result = Test-ServerResponse -InputObject $response -Method Get -RetryCount 0 -MaxRetries 3

            $result | Should -BeTrue
            Should -Invoke -CommandName Start-Sleep -ModuleName ConfluencePSVII -ParameterFilter {
                [Math]::Abs([double]$Seconds - 90.0) -lt 0.001
            } -Exactly -Times 1 -Scope It
        }

        It "uses capped exponential backoff when Retry-After is absent" {
            $response = [PSCustomObject]@{
                StatusCode = 429
                Headers    = @{}
            }

            $result = Test-ServerResponse -InputObject $response -Method Get -RetryCount 2 -MaxRetries 3

            $result | Should -BeTrue
            Should -Invoke -CommandName Start-Sleep -ModuleName ConfluencePSVII -ParameterFilter {
                [Math]::Abs([double]$Seconds - 60.0) -lt 0.001
            } -Exactly -Times 1 -Scope It
        }

        It "does not retry POST by default" {
            $response = [PSCustomObject]@{
                StatusCode = 503
                Headers    = @{ "Retry-After" = "10" }
            }

            $result = Test-ServerResponse -InputObject $response -Method Post -RetryCount 0 -MaxRetries 3

            $result | Should -BeNullOrEmpty
            Should -Invoke -CommandName Start-Sleep -ModuleName ConfluencePSVII -Exactly -Times 0 -Scope It
        }
    }
}
