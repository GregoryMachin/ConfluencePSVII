function Get-FooterComment {
    [CmdletBinding(
        SupportsPaging = $true,
        DefaultParameterSetName = "byId"
    )]
    [OutputType([ConfluencePSVII.Comment])]
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
        [UInt64[]]$CommentID,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byPage",
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [UInt64]$PageID,

        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]$PageSize = 25,

        [Switch]$ExcludeBody
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$ApiUri/content{0}"

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Get'
        $iwParameters['GetParameters'] = @{
            expand = "body.storage,version"
            limit  = $PageSize
        }
        if ($ExcludeBody) {
            $iwParameters.GetParameters.expand = "version"
        }
        # -OutputType dispatches to ConvertTo-Comment with no arguments, so its -Type
        # parameter default ('footer') applies -- correct for this command.
        $iwParameters['OutputType'] = [ConfluencePSVII.Comment]

        $useCloudV2 = ($DeploymentType -eq 'Cloud') -and $BaseUri
        $iwParametersV2 = $null
        if ($useCloudV2) {
            $iwParametersV2 = Copy-CommonParameter -InputObject $PSBoundParameters
            $iwParametersV2['Method'] = 'Get'
            $iwParametersV2['GetParameters'] = @{ limit = $PageSize }
            if (-not $ExcludeBody) {
                $iwParametersV2.GetParameters['body-format'] = 'storage'
            }
        }
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        switch ($PsCmdlet.ParameterSetName) {
            "byId" {
                if ($useCloudV2) {
                    ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                        $iwParametersV2[$_] = $PSCmdlet.PagingParameters.$_
                    }

                    foreach ($_commentID in $CommentID) {
                        $iwParametersV2["Uri"] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource FooterCommentById -CommentId $_commentID

                        Invoke-Method @iwParametersV2 | ConvertTo-CommentV2 -Type footer -BaseUri $BaseUri
                    }
                    break
                }

                foreach ($_commentID in $CommentID) {
                    $iwParameters["Uri"] = $resourceApi -f "/$_commentID"

                    Invoke-Method @iwParameters
                }
                break
            }
            "byPage" {
                if ($useCloudV2) {
                    ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
                        $iwParametersV2[$_] = $PSCmdlet.PagingParameters.$_
                    }
                    $iwParametersV2["Uri"] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource FooterCommentCollection -PageId $PageID

                    Invoke-Method @iwParametersV2 | ConvertTo-CommentV2 -Type footer -BaseUri $BaseUri
                    break
                }

                $iwParameters["Uri"] = $resourceApi -f "/$PageID/child/comment"

                Invoke-Method @iwParameters
                break
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
