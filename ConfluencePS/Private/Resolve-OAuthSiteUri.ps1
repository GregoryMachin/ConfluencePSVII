function Resolve-OAuthSiteUri {
    <#
    .SYNOPSIS
    Validates and normalizes a Confluence Cloud site URL returned by the OAuth
    accessible-resources endpoint.

    .DESCRIPTION
    Mirrors JiraPS's Resolve-JiraOAuthSiteUri: the accessible-resources response's `url` field
    must be an absolute HTTPS URL on the default port, with no userinfo, an `atlassian.net`
    host, and a root (or empty) path, query, and fragment. Anything else is rejected rather
    than silently accepted, since this value is later used to match a caller-supplied
    -SiteUrl selector.
    #>
    [CmdletBinding()]
    [OutputType([System.Uri])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Url
    )

    [Uri]$parsedUri = $null
    if (-not [Uri]::TryCreate($Url, [UriKind]::Absolute, [ref]$parsedUri)) {
        throw [System.ArgumentException]::new("Site URL '$Url' is not an absolute URI.", 'Url')
    }

    if ($parsedUri.Scheme -ne 'https') {
        throw [System.ArgumentException]::new("Site URL '$Url' must use HTTPS.", 'Url')
    }

    if (-not $parsedUri.IsDefaultPort) {
        throw [System.ArgumentException]::new("Site URL '$Url' must use the default HTTPS port.", 'Url')
    }

    if (-not [String]::IsNullOrEmpty($parsedUri.UserInfo)) {
        throw [System.ArgumentException]::new("Site URL '$Url' must not contain user info.", 'Url')
    }

    if ($parsedUri.Host -notmatch '(?i:\.atlassian\.net$)') {
        throw [System.ArgumentException]::new("Site URL '$Url' must be an atlassian.net host.", 'Url')
    }

    if (($parsedUri.AbsolutePath -ne '/') -and ($parsedUri.AbsolutePath -ne '')) {
        throw [System.ArgumentException]::new("Site URL '$Url' must not contain a path.", 'Url')
    }

    if (-not [String]::IsNullOrEmpty($parsedUri.Query) -or -not [String]::IsNullOrEmpty($parsedUri.Fragment)) {
        throw [System.ArgumentException]::new("Site URL '$Url' must not contain a query or fragment.", 'Url')
    }

    [Uri]("https://{0}/" -f $parsedUri.Host)
}
