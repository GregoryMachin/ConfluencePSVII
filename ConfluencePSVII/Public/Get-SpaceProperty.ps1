function Get-SpaceProperty {
    <#
    .NOTES
    Cloud v2 only: Confluence space properties (arbitrary JSON key/value metadata attached to
    a space) are exposed only by Cloud v2, with no v1/Data Center equivalent resource at all.
    There is no -DeploymentType parameter here and -BaseUri is mandatory.
    #>
    [CmdletBinding(
        SupportsPaging = $true,
        DefaultParameterSetName = "byKey"
    )]
    [OutputType([ConfluencePSVII.SpaceProperty])]
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
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [UInt64]$SpaceID,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byId",
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [Alias('ID')]
        [UInt64[]]$PropertyID,

        [Parameter(ParameterSetName = "byKey")]
        [ValidateNotNullOrEmpty()]
        [String]$Key,

        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Get'
        $iwParameters['GetParameters'] = @{ limit = $PageSize }
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        switch ($PsCmdlet.ParameterSetName) {
            "byId" {
                foreach ($_propertyID in $PropertyID) {
                    $iwParameters["Uri"] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource SpacePropertyById -SpaceId $SpaceID -PropertyId $_propertyID

                    Invoke-Method @iwParameters | ConvertTo-SpacePropertyV2 -SpaceID $SpaceID
                }
                break
            }
            "byKey" {
                $iwParameters["Uri"] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource SpacePropertyCollection -SpaceId $SpaceID
                if ($Key) { $iwParameters["GetParameters"]["key"] = $Key }

                Invoke-Method @iwParameters | ConvertTo-SpacePropertyV2 -SpaceID $SpaceID
                break
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
