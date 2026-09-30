function Get-Space {
    [CmdletBinding(
        SupportsPaging = $true
    )]
    [OutputType([ConfluencePSVII.Space])]
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
            Position = 0
        )]
        [Alias('Key')]
        [String[]]$SpaceKey,

        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$ApiUri/space{0}"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Cloud v2 opt-in (Task 45): -BaseUri + -DeploymentType Cloud route every key/all-spaces
        # read through the /spaces collection in one request, using its `keys` filter instead
        # of one v1-style /space/{key} lookup per key. A key that does not exist is silently
        # omitted from v2 results rather than producing a per-key error like v1 does; this
        # does not disclose anything about inaccessible spaces, so no mitigation is needed.
        $useCloudV2 = ($DeploymentType -eq 'Cloud') -and $BaseUri
        if ($useCloudV2) {
            $v2Parameters = Copy-CommonParameter -InputObject $PSBoundParameters
            $v2Parameters['Method'] = 'Get'
            $v2Parameters['GetParameters'] = @{
                limit                = $PageSize
                'description-format' = 'plain'
                'include-icon'       = 'true'
            }
            if ($SpaceKey) {
                $v2Parameters['GetParameters']['keys'] = $SpaceKey -join ','
            }
            $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource SpaceCollection

            # Paging
            ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                $v2Parameters[$_] = $PSCmdlet.PagingParameters.$_
            }

            Invoke-Method @v2Parameters | ConvertTo-SpaceV2
            return
        }

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Get'
        $iwParameters['GetParameters'] = @{
            expand = "description.plain,icon,homepage"
            limit  = $PageSize
        }
        $iwParameters['OutputType'] = [ConfluencePSVII.Space]

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        if ($SpaceKey) {
            foreach ($_space in $SpaceKey) {
                $iwParameters["Uri"] = $resourceApi -f "/$_space"

                Invoke-Method @iwParameters
            }
        }
        else {
            $iwParameters["Uri"] = $resourceApi -f ""

            Invoke-Method @iwParameters
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
