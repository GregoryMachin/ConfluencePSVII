function New-Space {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = "byObject"
    )]
    [OutputType([ConfluencePS.Space])]
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
            Mandatory = $true,
            ParameterSetName = "byObject",
            ValueFromPipeline = $true
        )]
        [ConfluencePS.Space]$InputObject,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byProperties"
        )]
        [Alias('Key')]
        [String]$SpaceKey,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = "byProperties"
        )]
        [String]$Name,

        [Parameter(
            ParameterSetName = "byProperties"
        )]
        [String]$Description
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$ApiUri/space"

        # Cloud v2 opt-in (Task 49): -BaseUri + -DeploymentType Cloud route space creation to
        # POST /spaces. The v2 request body is flat (description.value/description.representation
        # directly, not nested under a "plain" key the way v1's request body and every v2
        # response body are), matching the same request/response asymmetry as page create (Task 48).
        $useCloudV2 = ($DeploymentType -eq 'Cloud') -and $BaseUri
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($PsCmdlet.ParameterSetName -eq "byObject") {
            $SpaceKey = $InputObject.Key
            $Name = $InputObject.Name
            $Description = $InputObject.Description
        }

        if ($useCloudV2) {
            $v2Content = [Ordered]@{
                key  = $SpaceKey
                name = $Name
            }
            if ($Description) {
                $v2Content['description'] = @{
                    representation = 'plain'
                    value          = $Description
                }
            }

            $v2Parameters = Copy-CommonParameter -InputObject $PSBoundParameters
            $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource SpaceCreate
            $v2Parameters['Method'] = 'Post'
            $v2Parameters['Body'] = $v2Content | ConvertTo-Json

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($v2Content | Out-String)"
            if ($PSCmdlet.ShouldProcess("$SpaceKey $Name")) {
                Invoke-Method @v2Parameters | ConvertTo-SpaceV2
            }
            return
        }

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Uri'] = $resourceApi
        $iwParameters['Method'] = 'Post'
        $iwParameters['OutputType'] = [ConfluencePS.Space]

        $Body = @{
            key         = $SpaceKey
            name        = $Name
            description = @{
                plain = @{
                    value          = $Description
                    representation = 'plain'
                }
            }
        }

        $iwParameters["Body"] = $Body | ConvertTo-Json

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Body | Out-String)"
        If ($PSCmdlet.ShouldProcess("$SpaceKey $Name")) {
            Invoke-Method @iwParameters
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
