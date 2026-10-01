function Get-PageVersion {
    # -VersionNumber's response shape on Cloud v2 (a specific historical revision of the page,
    # optionally with body via -IncludeBody) is based on the same field conventions as the main
    # page v2 response and has not been live-verified against a Cloud tenant; treat it as
    # best-effort until confirmed. The byList path (both v1 and v2) is the well-established
    # version-history collection and carries no such caveat.
    [CmdletBinding(
        SupportsPaging = $true,
        DefaultParameterSetName = "byList"
    )]
    [OutputType([ConfluencePSVII.Version], ParameterSetName = 'byList')]
    [OutputType([ConfluencePSVII.Page], ParameterSetName = 'byVersion')]
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

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byVersion"
        )]
        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]$VersionNumber,

        [Parameter(ParameterSetName = "byVersion")]
        [Switch]$IncludeBody,

        [Parameter(ParameterSetName = "byList")]
        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $useCloudV2 = ($DeploymentType -eq 'Cloud') -and $BaseUri
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        switch ($PsCmdlet.ParameterSetName) {
            "byList" {
                if ($useCloudV2) {
                    $v2Parameters = Copy-CommonParameter -InputObject $PSBoundParameters
                    $v2Parameters['Method'] = 'Get'
                    $v2Parameters['GetParameters'] = @{ limit = $PageSize }
                    $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource PageVersionCollection -PageId $PageID

                    ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                        $v2Parameters[$_] = $PSCmdlet.PagingParameters.$_
                    }

                    Invoke-Method @v2Parameters | ConvertTo-VersionV2
                    break
                }

                $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
                $iwParameters['Method'] = 'Get'
                $iwParameters['GetParameters'] = @{ limit = $PageSize }
                $iwParameters['Uri'] = "$ApiUri/content/$PageID/version"
                $iwParameters['OutputType'] = [ConfluencePSVII.Version]

                ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                    $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
                }

                Invoke-Method @iwParameters
                break
            }
            "byVersion" {
                if ($useCloudV2) {
                    $v2Parameters = Copy-CommonParameter -InputObject $PSBoundParameters
                    $v2Parameters['Method'] = 'Get'
                    $v2Parameters['GetParameters'] = @{}
                    if ($IncludeBody) {
                        $v2Parameters['GetParameters']['body-format'] = 'storage'
                    }
                    $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource PageVersionById -PageId $PageID -VersionNumber $VersionNumber

                    Invoke-Method @v2Parameters | ConvertTo-PageV2 -BaseUri $BaseUri
                    break
                }

                $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
                $iwParameters['Method'] = 'Get'
                $iwParameters['GetParameters'] = @{ version = $VersionNumber }
                if ($IncludeBody) {
                    $iwParameters['GetParameters']['expand'] = 'body.storage,version'
                }
                else {
                    $iwParameters['GetParameters']['expand'] = 'version'
                }
                $iwParameters['Uri'] = "$ApiUri/content/$PageID"
                $iwParameters['OutputType'] = [ConfluencePSVII.Page]

                Invoke-Method @iwParameters
                break
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
