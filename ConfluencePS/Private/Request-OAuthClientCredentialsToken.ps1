function Request-OAuthClientCredentialsToken {
    <#
    .SYNOPSIS
    Exchanges an OAuth 2.0 client-credentials pair for a Cloud access token.

    .DESCRIPTION
    Near-direct port of JiraPS's Request-JiraOAuthClientCredentialsToken: POSTs to Atlassian's
    shared `https://auth.atlassian.com/oauth/token` endpoint (not Confluence-specific, so this
    is never resolved through Resolve-ConfluenceRoute and never goes through
    Invoke-ConfluenceMethod), keeps the client secret and access token as SecureString outside
    of the request itself, and redacts the client secret from any error message before
    re-throwing, since an HTTP error body could otherwise echo it back.
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSAvoidUsingConvertToSecureStringWithPlainText",
        "",
        Justification = "The OAuth token endpoint returns a plaintext access token; it is stored as SecureString in memory only."
    )]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ClientId,

        [Parameter(Mandatory)]
        [SecureString]
        $ClientSecret
    )

    $clientSecretPlain = $null
    $accessTokenPlain = $null
    try {
        $clientSecretPlain = [System.Net.NetworkCredential]::new('', $ClientSecret).Password
        if ([String]::IsNullOrWhiteSpace($clientSecretPlain)) {
            throw [System.ArgumentException]::new('OAuthClientSecret must not be empty.', 'OAuthClientSecret')
        }

        $body = @{
            grant_type    = 'client_credentials'
            client_id     = $ClientId
            client_secret = $clientSecretPlain
            audience      = 'api.atlassian.com'
        } | ConvertTo-Json -Compress

        Set-TlsLevel -Tls12
        $response = Invoke-WebRequest `
            -Uri 'https://auth.atlassian.com/oauth/token' `
            -Method Post `
            -Headers @{ Accept = 'application/json' } `
            -ContentType 'application/json' `
            -Body ([Text.Encoding]::UTF8.GetBytes($body)) `
            -UseBasicParsing `
            -ErrorAction Stop

        $payload = ConvertFrom-Json -InputObject ([String]$response.Content)
        $accessTokenPlain = [String]$payload.access_token
        if ([String]::IsNullOrWhiteSpace($accessTokenPlain)) {
            throw [System.InvalidOperationException]::new('OAuth token response did not contain an access token.')
        }

        $expiresIn = [Int]$payload.expires_in
        if ($expiresIn -le 0) {
            throw [System.InvalidOperationException]::new('OAuth token response did not contain a valid expiry.')
        }

        [PSCustomObject]@{
            AccessToken = ConvertTo-SecureString -String $accessTokenPlain -AsPlainText -Force
            ExpiresAt   = [DateTimeOffset]::UtcNow.AddSeconds($expiresIn)
            TokenType   = [String]$payload.token_type
            Scopes      = [String[]]@(([String]$payload.scope -split '\s+') | Where-Object { $_ })
        }
    }
    catch {
        $statusCode = $null
        $errorText = $null
        if ($_.Exception.Response) {
            try {
                $statusCode = [Int]$_.Exception.Response.StatusCode
                $stream = $_.Exception.Response.GetResponseStream()
                $reader = [System.IO.StreamReader]::new($stream)
                $errorPayload = $reader.ReadToEnd()
                if ($errorPayload) {
                    $errorJson = $errorPayload | ConvertFrom-Json -ErrorAction SilentlyContinue
                    if ($errorJson.error -or $errorJson.error_description) {
                        $errorText = @($errorJson.error, $errorJson.error_description | Where-Object { $_ }) -join ': '
                    }
                }
            }
            catch {
                Write-Verbose "OAuth client-credentials error response body could not be parsed: $($_.Exception.Message)"
            }
        }
        if ([String]::IsNullOrWhiteSpace($errorText)) {
            $errorText = $_.Exception.Message
        }
        if ($clientSecretPlain) {
            $errorText = $errorText -replace [Regex]::Escape([String]$clientSecretPlain), '<redacted>'
        }
        $message = if ($statusCode) {
            "OAuth client-credentials token exchange failed with HTTP $statusCode. $errorText"
        }
        else {
            "OAuth client-credentials token exchange failed. $errorText"
        }
        throw [System.InvalidOperationException]::new($message, $_.Exception)
    }
    finally {
        Set-TlsLevel -Revert
        $clientSecretPlain = $null
        $accessTokenPlain = $null
        $body = $null
    }
}
