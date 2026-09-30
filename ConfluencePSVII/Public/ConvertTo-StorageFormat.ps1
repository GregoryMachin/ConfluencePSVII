function ConvertTo-StorageFormat {
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter( Mandatory = $true )]
        [Uri]$ApiUri,

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
            ValueFromPipeline = $true
        )]
        [String[]]$Content,

        [Parameter()]
        [Switch]$AsPlainText
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        # Task 49: deliberately no -BaseUri/-DeploymentType routing here. Cloud v2 has no
        # synchronous storage-format conversion route; its only replacement returns a
        # pollable background task instead of a converted string, which would break this
        # command's output contract. Always call the v1 synchronous endpoint.
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Uri'] = "$ApiUri/contentbody/convert/storage"
        $iwParameters['Method'] = 'Post'
        $plainTextMarkupPattern = '[!"#$%&''()*+,\-./:;<=>?@\[\\\]\^_`{|}~]'

        foreach ($_content in $Content) {
            if ($AsPlainText) {
                $_content = [Regex]::Replace(
                    $_content,
                    $plainTextMarkupPattern,
                    { param($match) "&#$([Int32][Char]$match.Value);" }
                )
            }

            $iwParameters['Body'] = @{
                value          = "$_content"
                representation = 'wiki'
            } | ConvertTo-Json

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($_content | Out-String)"
            (Invoke-Method @iwParameters).value
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
