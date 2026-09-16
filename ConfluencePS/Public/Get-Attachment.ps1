function Get-Attachment {
    [CmdletBinding( SupportsPaging = $true )]
    [OutputType([ConfluencePS.Attachment])]
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
        [UInt64[]]$PageID,

        [String]$FileNameFilter,

        [String]$MediaTypeFilter,

        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not($_ -is [ConfluencePS.Page] -or $_ -is [UInt64])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        # Cloud v2 opt-in (Task 47): -BaseUri + -DeploymentType Cloud route attachment
        # metadata reads to GET /pages/{id}/attachments, converted through
        # ConvertTo-AttachmentV2. Upload, update, and download stay v1-only always (Cloud
        # v2 has no equivalent operation for any of them).
        $useCloudV2 = ($DeploymentType -eq 'Cloud') -and $BaseUri

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Get'
        $iwParameters['GetParameters'] = @{
            limit = $PageSize
        }
        if (-not $useCloudV2) {
            $iwParameters['GetParameters']['expand'] = 'version'
            $iwParameters['OutputType'] = [ConfluencePS.Attachment]
        }

        if ($FileNameFilter) {
            $iwParameters["GetParameters"]["filename"] = $FileNameFilter
        }

        if ($MediaTypeFilter) {
            $iwParameters["GetParameters"]["mediaType"] = $MediaTypeFilter
        }

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        foreach ($_PageID in $PageID) {
            if ($useCloudV2) {
                $iwParameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource AttachmentCollection -PageId $_PageID
                Invoke-Method @iwParameters | ConvertTo-AttachmentV2 -BaseUri $BaseUri
            }
            else {
                $iwParameters['Uri'] = "$ApiUri/content/{0}/child/attachment" -f $_PageID
                Invoke-Method @iwParameters
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
