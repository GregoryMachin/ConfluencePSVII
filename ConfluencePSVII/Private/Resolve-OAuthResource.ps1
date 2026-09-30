function Resolve-OAuthResource {
    <#
    .SYNOPSIS
    Filters a set of OAuth accessible-resources down to at most one match.

    .DESCRIPTION
    Mirrors JiraPSVII's Resolve-JiraOAuthResource: given at most one of -CloudId, -SiteName, or
    -SiteUrl, returns the single matching resource, or throws ItemNotFoundException /
    InvalidOperationException for zero or multiple matches respectively. Comparisons are
    case-sensitive (-ceq) since CloudId and site host names are both normalized values. With no
    selector, the full, unfiltered list is returned.
    #>
    [CmdletBinding()]
    [OutputType([ConfluencePSVII.OAuthResource])]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [ConfluencePSVII.OAuthResource[]]
        $Resource,

        [Parameter()]
        [String]
        $CloudId,

        [Parameter()]
        [String]
        $SiteName,

        [Parameter()]
        [Uri]
        $SiteUrl
    )

    $selectorCount = @($CloudId, $SiteName, $SiteUrl) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
    if ($selectorCount -gt 1) {
        throw [System.ArgumentException]::new('Specify only one OAuth resource selector: CloudId, SiteName, or SiteUrl.')
    }

    if ($selectorCount -eq 0) {
        return $Resource
    }

    $matchedResources = if ($CloudId) {
        [Guid]$parsedCloudId = [Guid]::Empty
        if (-not [Guid]::TryParseExact($CloudId, 'D', [ref]$parsedCloudId)) {
            throw [System.ArgumentException]::new("CloudId must be a UUID in 'D' format, for example '11223344-a1b2-3b33-c444-def123456789'.", 'CloudId')
        }
        @($Resource | Where-Object { $_.CloudId -ceq $parsedCloudId.ToString('D') })
    }
    elseif ($SiteName) {
        @($Resource | Where-Object { $_.Name -ceq $SiteName })
    }
    else {
        $normalizedSiteUrl = Resolve-OAuthSiteUri -Url $SiteUrl.AbsoluteUri
        @($Resource | Where-Object { $_.Url.AbsoluteUri -ceq $normalizedSiteUrl.AbsoluteUri })
    }

    if ($matchedResources.Count -eq 0) {
        throw [System.Management.Automation.ItemNotFoundException]::new('No accessible OAuth resource matched the given selector.')
    }
    if ($matchedResources.Count -gt 1) {
        throw [System.InvalidOperationException]::new('Multiple accessible OAuth resources matched the given selector; narrow the selector further.')
    }

    $matchedResources[0]
}
