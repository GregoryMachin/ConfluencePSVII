function Get-SpaceRoleAssignment {
    # Cloud v2 only: Confluence space role assignments are exposed as a dedicated queryable
    # resource only by Cloud v2, with no v1/Data Center equivalent resource at all. There is no
    # -DeploymentType parameter here and -BaseUri is mandatory.
    [CmdletBinding(
        SupportsPaging = $true
    )]
    [OutputType([ConfluencePSVII.SpaceRoleAssignment])]
    param (
        [Parameter( Mandatory = $true )]
        [Uri]$ApiUri,

        [Parameter( Mandatory = $true )]
        [Uri]$BaseUri,

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
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [UInt64]$SpaceID,

        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Get'
        $iwParameters['GetParameters'] = @{ limit = $PageSize }
        $iwParameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource SpaceRoleAssignmentCollection -SpaceId $SpaceID

        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        Invoke-Method @iwParameters | ConvertTo-SpaceRoleAssignmentV2 -SpaceID $SpaceID
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
