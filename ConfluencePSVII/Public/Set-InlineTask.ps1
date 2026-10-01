function Set-InlineTask {
    # Cloud v2 only, same reasoning as Get-InlineTask: inline tasks have no v1/Data Center
    # status-update API at all, only inline markup inside a page body. There is no
    # -DeploymentType parameter here and -BaseUri is mandatory. The only supported mutation is
    # -Status (complete/incomplete); task body/assignee/due-date editing is not exposed here,
    # since those are edited through the owning page's body, not this resource.
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true
    )]
    [OutputType([ConfluencePSVII.InlineTask])]
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
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [Alias('ID')]
        [UInt64]$TaskID,

        [Parameter( Mandatory = $true )]
        [ValidateSet('complete', 'incomplete')]
        [String]$Status
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $authApiAndBaseUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter @('ApiUri', 'BaseUri')
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $originalTask = Get-InlineTask -TaskID $TaskID @authApiAndBaseUri
        $versionNumber = ++$originalTask.Version.Number

        $v2Content = [Ordered]@{
            id      = [String]$TaskID
            status  = $Status
            version = @{
                number = $versionNumber
            }
        }

        $v2Parameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource InlineTaskUpdate -TaskId $TaskID
        $v2Parameters['Method'] = 'Put'
        $v2Parameters['Body'] = $v2Content | ConvertTo-Json

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($v2Content | Out-String)"
        if ($PSCmdlet.ShouldProcess("TaskID $TaskID", "Set status to '$Status'")) {
            Invoke-Method @v2Parameters | ConvertTo-InlineTaskV2
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
