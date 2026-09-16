function Get-Page {
    [CmdletBinding(
        SupportsPaging = $true,
        DefaultParameterSetName = "byId"
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
            ParameterSetName = "byId",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [Alias('ID')]
        [UInt64[]]$PageID,

        [Parameter(
            ParameterSetName = "bySpace"
        )]
        [Parameter(
            ParameterSetName = "bySpaceObject"
        )]
        [Alias('Name')]
        [String]$Title,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "bySpace"
        )]
        [Parameter(
            ParameterSetName = "byLabel"
        )]
        [Alias('Key')]
        [String]$SpaceKey,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "bySpaceObject"
        )]
        [Parameter(
            ValueFromPipeline = $true,
            ParameterSetName = "byLabel"
        )]
        [ConfluencePS.Space]$Space,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byLabel"
        )]
        [ValidateNotNullOrEmpty()]
        [String[]]$Label,

        [Parameter(ParameterSetName = "byLabel")]
        [ValidateSet('current', 'archived', 'trashed')]
        [String[]]$Status = 'current',

        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "byQuery"
        )]
        [String]$Query,

        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]$PageSize = 25,

        [Switch]$ExcludePageBody
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$ApiUri/content{0}"

        #setup defaults that don't change based on the pipeline or the parameter set
        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Get'
        $iwParameters['GetParameters'] = @{
            expand = "space,version,body.storage,ancestors"
            limit  = $PageSize
        }

        if ($ExcludePageBody) {
            $iwParameters.GetParameters.expand = "space,version,ancestors"
        }

        $iwParameters['OutputType'] = [ConfluencePS.Page]

        # Only the byId parameter set has a Cloud v2 route today (see Resolve-ConfluenceRoute).
        # bySpace/byLabel/byQuery stay on v1: v2's page collection filters by numeric space ID
        # rather than space key, and CQL search has no v2 equivalent at all.
        $useCloudV2 = ($DeploymentType -eq 'Cloud') -and $BaseUri
        $iwParametersV2 = $null
        if ($useCloudV2) {
            $iwParametersV2 = Copy-CommonParameter -InputObject $PSBoundParameters
            $iwParametersV2['Method'] = 'Get'
            $iwParametersV2['GetParameters'] = @{ limit = $PageSize }
            if (-not $ExcludePageBody) {
                $iwParametersV2.GetParameters['body-format'] = 'storage'
            }

            # Paging is applied per-call below since it depends on $PSCmdlet.PagingParameters.
        }
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($Space -is [ConfluencePS.Space] -and ($Space.Key)) {
            $SpaceKey = $Space.Key
        }

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        switch -regex ($PsCmdlet.ParameterSetName) {
            "byId" {
                if ($useCloudV2) {
                    ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                        $iwParametersV2[$_] = $PSCmdlet.PagingParameters.$_
                    }

                    foreach ($_pageID in $PageID) {
                        $iwParametersV2["Uri"] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource PageById -PageId $_pageID

                        Invoke-Method @iwParametersV2 | ConvertTo-PageV2 -BaseUri $BaseUri
                    }
                    break
                }

                foreach ($_pageID in $PageID) {
                    $iwParameters["Uri"] = $resourceApi -f "/$_pageID"

                    Invoke-Method @iwParameters
                }
                break
            }
            "bySpace" {
                # This includes 'bySpaceObject'
                $iwParameters["Uri"] = $resourceApi -f ''
                $iwParameters["GetParameters"]["type"] = "page"
                if ($SpaceKey) { $iwParameters["GetParameters"]["spaceKey"] = $SpaceKey }

                if ($Title) {
                    Invoke-Method @iwParameters | Where-Object { $_.Title -like "$Title" }
                }
                else {
                    Invoke-Method @iwParameters
                }
                break
            }
            "byLabel" {
                $iwParameters["Uri"] = $resourceApi -f "/search"

                $CQLparameters = @("type=page")
                $Label | ForEach-Object { $CQLparameters += "label=`"$_`"" }
                if ($SpaceKey) { $CQLparameters += "space=$SpaceKey" }
                $iwParameters["GetParameters"]["cql"] = ($CQLparameters -join " AND ")

                Invoke-Method @iwParameters | Where-Object { $_.Status -in $Status }
                break
            }
            "byQuery" {
                $iwParameters["Uri"] = $resourceApi -f "/search"

                $iwParameters["GetParameters"]["cql"] = "type=page AND $Query"

                Invoke-Method @iwParameters
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
