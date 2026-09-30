function Get-BlogPost {
    [CmdletBinding(
        SupportsPaging = $true,
        DefaultParameterSetName = "byId"
    )]
    [OutputType([ConfluencePSVII.BlogPost])]
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
        [UInt64[]]$BlogPostID,

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
        [Alias('Key')]
        [String]$SpaceKey,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "bySpaceObject"
        )]
        [ConfluencePSVII.Space]$Space,

        [Parameter(
            Position = 0,
            Mandatory = $true,
            ParameterSetName = "byQuery"
        )]
        [String]$Query,

        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]$PageSize = 25,

        [Switch]$ExcludeBody
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$ApiUri/content{0}"

        $authApiAndBaseUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter @('ApiUri', 'BaseUri', 'DeploymentType')

        #setup defaults that don't change based on the pipeline or the parameter set
        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Get'
        $iwParameters['GetParameters'] = @{
            expand = "space,version,body.storage"
            limit  = $PageSize
        }

        if ($ExcludeBody) {
            $iwParameters.GetParameters.expand = "space,version"
        }

        $iwParameters['OutputType'] = [ConfluencePSVII.BlogPost]

        # Only the byId and bySpace(Object) parameter sets have a Cloud v2 route; byQuery stays
        # on v1 CQL search, which has no v2 equivalent -- the same parity gap Get-Page documents.
        $useCloudV2 = ($DeploymentType -eq 'Cloud') -and $BaseUri
        $iwParametersV2 = $null
        if ($useCloudV2) {
            $iwParametersV2 = Copy-CommonParameter -InputObject $PSBoundParameters
            $iwParametersV2['Method'] = 'Get'
            $iwParametersV2['GetParameters'] = @{ limit = $PageSize }
            if (-not $ExcludeBody) {
                $iwParametersV2.GetParameters['body-format'] = 'storage'
            }

            # Paging is applied per-call below since it depends on $PSCmdlet.PagingParameters.
        }
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($Space -is [ConfluencePSVII.Space] -and ($Space.Key)) {
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

                    foreach ($_blogPostID in $BlogPostID) {
                        $iwParametersV2["Uri"] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource BlogPostById -PageId $_blogPostID

                        Invoke-Method @iwParametersV2 | ConvertTo-BlogPostV2 -BaseUri $BaseUri
                    }
                    break
                }

                foreach ($_blogPostID in $BlogPostID) {
                    $iwParameters["Uri"] = $resourceApi -f "/$_blogPostID"

                    Invoke-Method @iwParameters
                }
                break
            }
            "bySpace" {
                # This includes 'bySpaceObject'
                if ($useCloudV2) {
                    $spaceId = (Get-Space -SpaceKey $SpaceKey @authApiAndBaseUri).Id

                    ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                        $iwParametersV2[$_] = $PSCmdlet.PagingParameters.$_
                    }
                    $iwParametersV2["GetParameters"]["space-id"] = $spaceId
                    $iwParametersV2["Uri"] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource BlogPostCollection

                    if ($Title) {
                        Invoke-Method @iwParametersV2 | ConvertTo-BlogPostV2 -BaseUri $BaseUri | Where-Object { $_.Title -like "$Title" }
                    }
                    else {
                        Invoke-Method @iwParametersV2 | ConvertTo-BlogPostV2 -BaseUri $BaseUri
                    }
                    break
                }

                $iwParameters["Uri"] = $resourceApi -f ''
                $iwParameters["GetParameters"]["type"] = "blogpost"
                if ($SpaceKey) { $iwParameters["GetParameters"]["spaceKey"] = $SpaceKey }

                if ($Title) {
                    Invoke-Method @iwParameters | Where-Object { $_.Title -like "$Title" }
                }
                else {
                    Invoke-Method @iwParameters
                }
                break
            }
            "byQuery" {
                $iwParameters["Uri"] = $resourceApi -f "/search"

                $iwParameters["GetParameters"]["cql"] = "type=blogpost AND $Query"

                Invoke-Method @iwParameters
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
