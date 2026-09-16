function Get-PageAncestor {
    <#
    .NOTES
    Returns the same minimal ancestor shape (ID, Status, Title only -- no Body, Version, or
    Space) on both v1 and Cloud v2, matching the existing partial objects Get-Page has always
    populated on its own -Ancestors property. Ancestors are returned in root-to-parent order.
    #>
    [CmdletBinding(
        SupportsPaging = $true
    )]
    [OutputType([ConfluencePS.Page])]
    param (
        [Parameter( Mandatory = $true )]
        [Uri]$ApiUri,

        [Parameter( Mandatory = $false )]
        [Uri]$BaseUri,

        [Parameter( Mandatory = $false )]
        [ValidateSet('', 'Cloud', 'DataCenter', 'Server')]
        [String]$DeploymentType,

        [Parameter( Mandatory = $false )]
        [PSCredential]$Credential,

        [Parameter( Mandatory = $false )]
        [String]
        $PersonalAccessToken,

        [Parameter( Mandatory = $false )]
        [ValidateNotNull()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $Certificate,

        [Parameter(
            Position = 0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [Alias('ID')]
        [UInt64]$PageID,

        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $useCloudV2 = ($DeploymentType -eq 'Cloud') -and $BaseUri
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($useCloudV2) {
            $v2Parameters = Copy-CommonParameter -InputObject $PSBoundParameters
            $v2Parameters['Method'] = 'Get'
            $v2Parameters['GetParameters'] = @{ limit = $PageSize }
            $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource PageAncestor -PageId $PageID

            ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                $v2Parameters[$_] = $PSCmdlet.PagingParameters.$_
            }

            Invoke-Method @v2Parameters | ConvertTo-PageAncestorV2
            return
        }

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Get'
        $iwParameters['GetParameters'] = @{ expand = 'ancestors' }
        $iwParameters['Uri'] = "$ApiUri/content/$PageID"

        $response = Invoke-Method @iwParameters
        if ($response.ancestors) {
            $response.ancestors | ConvertTo-PageAncestor
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
