function Get-InlineTask {
    <#
    .NOTES
    Cloud v2 only: Confluence inline tasks (the checkbox action items embedded in a page's
    body) are exposed as a dedicated queryable resource only by Cloud v2; v1/Data Center only
    ever surfaced them as inline markup inside a page's storage-format body, with no separate
    listing/filtering/status API. There is no -DeploymentType parameter here and -BaseUri is
    mandatory.
    #>
    [CmdletBinding(
        SupportsPaging = $true,
        DefaultParameterSetName = "byFilter"
    )]
    [OutputType([ConfluencePS.InlineTask])]
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
        [UInt64[]]$TaskID,

        [Parameter(ParameterSetName = "byFilter")]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [UInt64]$PageID,

        [Parameter(ParameterSetName = "byFilter")]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [UInt64]$SpaceID,

        [Parameter(ParameterSetName = "byFilter")]
        [ValidateSet('complete', 'incomplete')]
        [String]$Status,

        [Parameter(ParameterSetName = "byFilter")]
        [ValidateNotNullOrEmpty()]
        [String]$AssignedTo,

        [Parameter(ParameterSetName = "byFilter")]
        [ValidateNotNullOrEmpty()]
        [String]$CreatedBy,

        [Parameter(ParameterSetName = "byFilter")]
        [DateTime]$CreatedAfter,

        [Parameter(ParameterSetName = "byFilter")]
        [DateTime]$CreatedBefore,

        [Parameter(ParameterSetName = "byFilter")]
        [DateTime]$DueAfter,

        [Parameter(ParameterSetName = "byFilter")]
        [DateTime]$DueBefore,

        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]$PageSize = 25
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

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
                foreach ($_taskID in $TaskID) {
                    $iwParameters["Uri"] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource InlineTaskById -TaskId $_taskID

                    Invoke-Method @iwParameters | ConvertTo-InlineTaskV2
                }
                break
            }
            "byFilter" {
                $iwParameters["Uri"] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource InlineTaskCollection

                if ($PageID) { $iwParameters["GetParameters"]["page-id"] = $PageID }
                if ($SpaceID) { $iwParameters["GetParameters"]["space-id"] = $SpaceID }
                if ($Status) { $iwParameters["GetParameters"]["status"] = $Status }
                if ($AssignedTo) { $iwParameters["GetParameters"]["assigned-to"] = $AssignedTo }
                if ($CreatedBy) { $iwParameters["GetParameters"]["created-by"] = $CreatedBy }
                if ($CreatedAfter) { $iwParameters["GetParameters"]["created-at-from"] = $CreatedAfter.ToUniversalTime().ToString('o') }
                if ($CreatedBefore) { $iwParameters["GetParameters"]["created-at-to"] = $CreatedBefore.ToUniversalTime().ToString('o') }
                if ($DueAfter) { $iwParameters["GetParameters"]["due-at-from"] = $DueAfter.ToUniversalTime().ToString('o') }
                if ($DueBefore) { $iwParameters["GetParameters"]["due-at-to"] = $DueBefore.ToUniversalTime().ToString('o') }

                Invoke-Method @iwParameters | ConvertTo-InlineTaskV2
                break
            }
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
