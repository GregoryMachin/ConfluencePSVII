function Set-Label {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true
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

        [Parameter( Mandatory = $true )]
        [String[]]$Label
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

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Post'
        $iwParameters['OutputType'] = [ConfluencePSVII.Label]

        $authAndApiUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter @('ApiUri', 'BaseUri', 'DeploymentType')
        foreach ($_page in $PageID) {
            if ($_ -is [ConfluencePSVII.Page]) {
                $InputObject = $_
            }
            else {
                $InputObject = Get-Page -PageID $_page @authAndApiUri
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Removing all previous labels"
            Remove-Label -PageID $_page @authAndApiUri | Out-Null

            $iwParameters["Uri"] = $resourceApi -f $_page
            $iwParameters["Body"] = $Label | ForEach-Object { @{prefix = 'global'; name = $_ } } | ConvertTo-Json

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($iwParameters["Body"] | Out-String)"
            if ($PSCmdlet.ShouldProcess("Label $Label, PageID $_page")) {
                $output = [ConfluencePSVII.ContentLabelSet]@{ Page = $InputObject }
                $output.Labels += (Invoke-Method @iwParameters)
                $output
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
