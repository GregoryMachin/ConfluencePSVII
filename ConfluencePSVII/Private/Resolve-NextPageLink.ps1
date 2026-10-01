function Resolve-NextPageLink {
    <#
    .SYNOPSIS
    Resolves the next-page URI from a Confluence response, if one was provided.

    .DESCRIPTION
    Confluence v1 collections advertise the next page as a relative `_links.next` path
    combined with `_links.base`. Confluence v2 collections advertise it the same way, but
    `_links.base` is not always present, and some v2 endpoints instead (or additionally) use
    an RFC 5988 `Link` response header with `rel="next"`. This function checks the response
    body first, then the `Link` header, and resolves whichever is found against the original
    request URI. It never follows a link to a different host or scheme than the request that
    produced it.
    #>
    [CmdletBinding()]
    [OutputType([Uri])]
    param(
        [Parameter(Mandatory)]
        [Uri]
        $RequestUri,

        [Parameter()]
        $ResponseBody,

        [Parameter()]
        $Headers
    )

    function Get-NextLinkFromHeader {
        param($Headers)

        if (-not $Headers) {
            return $null
        }

        $rawValues = @()
        if ($Headers -is [System.Collections.IDictionary]) {
            if ($Headers.ContainsKey('Link')) {
                $rawValues = @($Headers['Link'])
            }
        }
        elseif ($Headers.PSObject.Methods.Name -contains 'TryGetValues') {
            $headerValues = [string[]]@()
            if ($Headers.TryGetValues('Link', [ref]$headerValues)) {
                $rawValues = $headerValues
            }
        }

        if (-not $rawValues -or $rawValues.Count -eq 0) {
            return $null
        }

        $combined = ($rawValues -join ', ')
        $linkMatches = [Regex]::Matches($combined, '<(?<Url>[^>]+)>\s*;\s*rel\s*=\s*"?(?<Rel>[a-zA-Z]+)"?')
        foreach ($linkMatch in $linkMatches) {
            if ($linkMatch.Groups['Rel'].Value -eq 'next') {
                return $linkMatch.Groups['Url'].Value
            }
        }

        return $null
    }

    $nextRaw = $null
    $baseRaw = $null

    if ($ResponseBody -and $ResponseBody._links) {
        $nextRaw = $ResponseBody._links.next
        $baseRaw = $ResponseBody._links.base
    }

    if (-not $nextRaw) {
        $nextRaw = Get-NextLinkFromHeader -Headers $Headers
    }

    if (-not $nextRaw) {
        return $null
    }

    [Uri]$nextUri = $null
    # Only an http(s) URI counts as absolute: on Linux/macOS .NET also parses a leading-'/' path
    # such as "/wiki/rest/api/content?start=25" as an absolute file:// URI.
    $isAbsoluteLink = [Uri]::TryCreate([string]$nextRaw, [UriKind]::Absolute, [ref]$nextUri) -and $nextUri.Scheme -in @('http', 'https')
    if ($isAbsoluteLink) {
        # Already absolute, e.g. a typical `Link` header value.
    }
    elseif ($baseRaw) {
        $nextUri = [Uri]("{0}{1}" -f $baseRaw, $nextRaw)
    }
    else {
        $nextUri = [Uri]::new($RequestUri, [string]$nextRaw)
    }

    if ($nextUri.Host -ne $RequestUri.Host -or $nextUri.Scheme -ne $RequestUri.Scheme) {
        throw "Refusing to follow Confluence pagination link to an untrusted host."
    }

    return $nextUri
}
