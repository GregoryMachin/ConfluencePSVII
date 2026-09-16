function Get-Folder {
    <#
    .NOTES
    Cloud v2 only: Confluence folders (organizational containers for grouping content) do not
    exist in the legacy v1/Data Center content model at all, so there is no -DeploymentType
    parameter here and -BaseUri is mandatory. Read-only: no New-/Set-/Remove-ConfluenceFolder
    exists yet -- write support is deferred until this read model is proven stable, per this
    task's own scope.
    #>
    [CmdletBinding(
        SupportsPaging = $true,
        DefaultParameterSetName = "byId"
    )]
    [OutputType([ConfluencePS.Folder])]
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
            ParameterSetName = "byId",
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [Alias('ID')]
        [UInt64[]]$FolderID,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "bySpace"
        )]
        [Alias('Key')]
        [String]$SpaceKey,

        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $authApiAndBaseUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter @('ApiUri', 'BaseUri')

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
                foreach ($_folderID in $FolderID) {
                    $iwParameters["Uri"] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource FolderById -FolderId $_folderID

                    Invoke-Method @iwParameters | ConvertTo-FolderV2 -BaseUri $BaseUri
                }
                break
            }
            "bySpace" {
                $spaceId = (Get-Space -SpaceKey $SpaceKey @authApiAndBaseUri -DeploymentType Cloud).Id

                $iwParameters["Uri"] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource FolderCollection
                $iwParameters["GetParameters"]["space-id"] = $spaceId

                Invoke-Method @iwParameters | ConvertTo-FolderV2 -BaseUri $BaseUri
                break
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
