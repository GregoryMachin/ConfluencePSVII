function Remove-InlineComment {
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true
    )]
    [OutputType([Bool])]
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
        [UInt64[]]$CommentID
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$ApiUri/content/{0}"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if (($_) -and -not($_ -is [ConfluencePS.Comment] -or $_ -is [UInt64])) {
            $message = "The Object in the pipe is not a Comment."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            Throw $exception
        }

        # Cloud v2 opt-in (Task 51): -BaseUri + -DeploymentType Cloud route deletion to
        # DELETE /inline-comments/{id}.
        $useCloudV2 = ($DeploymentType -eq 'Cloud') -and $BaseUri

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Delete'

        foreach ($_comment in $CommentID) {
            if ($useCloudV2) {
                $iwParameters["Uri"] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource InlineCommentDelete -CommentId $_comment
            }
            else {
                $iwParameters["Uri"] = $resourceApi -f $_comment
            }

            If ($PSCmdlet.ShouldProcess("CommentID $_comment")) {
                Invoke-Method @iwParameters
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
