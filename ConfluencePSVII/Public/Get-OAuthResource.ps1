function Get-OAuthResource {
    <#
    .NOTES
    Cloud v2 only: this command discovers the Confluence sites (and other Atlassian Cloud
    products) an OAuth 2.0 (3LO) access token can reach, via
    https://api.atlassian.com/oauth/token/accessible-resources. It is an Atlassian identity
    endpoint external to any single Confluence site, so it takes -OAuthAccessToken directly
    rather than -BaseUri/-DeploymentType, and is never resolved through
    Resolve-ConfluenceRoute. This response shape has not been live-verified against a Cloud
    tenant; see docs/api-contract-inventory.md.
    #>
    [CmdletBinding(DefaultParameterSetName = "default")]
    [OutputType([ConfluencePSVII.OAuthResource])]
    param (
        [Parameter( Mandatory = $true )]
        [ValidateNotNull()]
        [SecureString]
        $OAuthAccessToken,

        [Parameter( Mandatory = $true, ParameterSetName = "byCloudId" )]
        [ValidateNotNullOrEmpty()]
        [String]
        $CloudId,

        [Parameter( Mandatory = $true, ParameterSetName = "bySiteName" )]
        [ValidateNotNullOrEmpty()]
        [String]
        $SiteName,

        [Parameter( Mandatory = $true, ParameterSetName = "bySiteUrl" )]
        [ValidateNotNull()]
        [Uri]
        $SiteUrl
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $selectorParameters = @{}
        foreach ($selectorName in 'CloudId', 'SiteName', 'SiteUrl') {
            if ($PSBoundParameters.ContainsKey($selectorName)) {
                $selectorParameters[$selectorName] = $PSBoundParameters[$selectorName]
            }
        }
    }

    PROCESS {
        $tokenPlain = [System.Net.NetworkCredential]::new('', $OAuthAccessToken).Password
        if ([String]::IsNullOrWhiteSpace($tokenPlain)) {
            throw [System.ArgumentException]::new('OAuthAccessToken must not be empty.', 'OAuthAccessToken')
        }

        try {
            $resources = @(
                Invoke-Method -Uri 'https://api.atlassian.com/oauth/token/accessible-resources' -Method Get -PersonalAccessToken $tokenPlain |
                    ConvertTo-OAuthResource
            )

            Resolve-OAuthResource -Resource $resources @selectorParameters
        }
        finally {
            $tokenPlain = $null
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
