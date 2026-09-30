function ConvertTo-OAuthResource {
    <#
    .SYNOPSIS
    Converts a raw accessible-resources item to the ConfluencePSVII.OAuthResource type.

    .DESCRIPTION
    Mirrors JiraPSVII's ConvertTo-JiraOAuthResource: normalizes `id` to a canonical UUID string,
    validates `url` via Resolve-OAuthSiteUri, and best-effort parses `avatarUrl` (an invalid or
    missing avatar URL becomes $null rather than a hard failure, since it is not needed to use
    the resource).
    #>
    [CmdletBinding()]
    [OutputType([ConfluencePSVII.OAuthResource])]
    param (
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        $InputObject
    )

    process {
        foreach ($object in $InputObject) {
            if ($null -eq $object) {
                continue
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Object to OAuthResource"

            [Guid]$parsedCloudId = [Guid]::Empty
            if (-not [Guid]::TryParse([String]$object.id, [ref]$parsedCloudId)) {
                throw [System.FormatException]::new("Accessible-resources item has an invalid id: '$($object.id)'.")
            }

            $avatarUri = $null
            if ($object.avatarUrl) {
                $parsedAvatarUri = $null
                if ([Uri]::TryCreate([String]$object.avatarUrl, [UriKind]::Absolute, [ref]$parsedAvatarUri)) {
                    $avatarUri = $parsedAvatarUri
                }
            }

            [ConfluencePSVII.OAuthResource]@{
                CloudId   = $parsedCloudId.ToString('D')
                Name      = [String]$object.name
                Url       = Resolve-OAuthSiteUri -Url ([String]$object.url)
                Scopes    = [String[]]@($object.scopes)
                AvatarUrl = $avatarUri
            }
        }
    }
}
