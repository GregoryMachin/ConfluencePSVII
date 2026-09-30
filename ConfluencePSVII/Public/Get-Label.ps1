function Get-Label {
    [CmdletBinding(
        SupportsPaging = $true
    )]
    [OutputType([ConfluencePSVII.ContentLabelSet])]
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

        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$ApiUri/content/{0}/label"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not($_ -is [ConfluencePSVII.Page] -or $_ -is [UInt64])) {
            $message = "The Object in the pipe is not a Page."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        # Cloud v2 opt-in (Task 46): -BaseUri + -DeploymentType Cloud route label reads to
        # GET /pages/{id}/labels. The Cloud v2 label shape is field-identical to v1
        # ({id, name, prefix}), so the existing ConvertTo-Label converter handles both and
        # no new v2-specific adapter is needed. Add-Label/Set-Label/Remove-Label stay on v1:
        # Cloud v2 has no label mutation operation at all.
        $useCloudV2 = ($DeploymentType -eq 'Cloud') -and $BaseUri

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Get'
        $iwParameters['GetParameters'] = @{
            limit = $PageSize
        }
        $iwParameters['OutputType'] = [ConfluencePSVII.Label]

        # Paging
        ($PSCmdlet.PagingParameters | Get-Member -MemberType Property).Name | ForEach-Object {
            $iwParameters[$_] = $PSCmdlet.PagingParameters.$_
        }

        $authAndApiUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter @('ApiUri', 'BaseUri', 'DeploymentType')
        foreach ($_page in $PageID) {
            if ($_ -is [ConfluencePSVII.Page]) {
                $InputObject = $_
            }
            else {
                $InputObject = Get-Page -PageID $_page @authAndApiUri
            }

            if ($useCloudV2) {
                $iwParameters["Uri"] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource LabelCollection -PageId $_page
            }
            else {
                $iwParameters["Uri"] = $resourceApi -f $_page
            }
            $output = New-Object -TypeName ConfluencePSVII.ContentLabelSet
            $output.Page = $InputObject
            $output.Labels += (Invoke-Method @iwParameters)
            $output
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
