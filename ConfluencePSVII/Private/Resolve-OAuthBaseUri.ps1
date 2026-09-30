function Resolve-OAuthBaseUri {
    <#
    .SYNOPSIS
    Builds the Atlassian Cloud API gateway base URI for a given Cloud ID.

    .DESCRIPTION
    Mirrors JiraPSVII's Resolve-JiraOAuthBaseUri: validates that CloudId is a UUID and returns the
    `/ex/confluence/{cloudId}` gateway URI that Set-ConfluenceInfo uses as -BaseUri for OAuth
    2.0 (3LO) Cloud sessions. This URI is external to any single Confluence site and is never
    resolved through Resolve-ConfluenceRoute.
    #>
    [CmdletBinding()]
    [OutputType([System.Uri])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $CloudId
    )

    [Guid]$parsedCloudId = [Guid]::Empty
    if (-not [Guid]::TryParseExact($CloudId, 'D', [ref]$parsedCloudId)) {
        throw [System.ArgumentException]::new("CloudId must be a UUID in 'D' format, for example '11223344-a1b2-3b33-c444-def123456789'.", 'CloudId')
    }

    [Uri]("https://api.atlassian.com/ex/confluence/{0}" -f $parsedCloudId.ToString('D'))
}
