function Set-SpaceRoleAssignment {
    <#
    .NOTES
    Cloud v2 only, same reasoning as Get-SpaceRoleAssignment. This is the only mutation
    surface Cloud v2 exposes for space access governance -- individual permission grants
    (Get-ConfluenceSpacePermission) cannot be changed directly, only role assignments.

    High-impact by design (ConfirmImpact High, so a confirmation prompt appears unless
    -Confirm:$false is passed explicitly): changing or removing a principal's role can revoke
    their access to the entire space. Genuine self-lockout detection (warning when the caller
    is about to remove their own admin access) would require resolving the caller's own Cloud
    account ID, which this module has no command for yet; the practical mitigation available
    today is requiring deliberate confirmation for every change, which this command enforces.
    #>
    [CmdletBinding(
        ConfirmImpact = 'High',
        SupportsShouldProcess = $true
    )]
    [OutputType([ConfluencePSVII.SpaceRoleAssignment])]
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
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [UInt64]$SpaceID,

        [Parameter( Mandatory = $true )]
        [ValidateSet('user', 'group')]
        [String]$PrincipalType,

        [Parameter( Mandatory = $true )]
        [ValidateNotNullOrEmpty()]
        [String]$PrincipalID,

        [Parameter( Mandatory = $true )]
        [ValidateNotNullOrEmpty()]
        [String]$RoleID
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $v2Content = @(
            [Ordered]@{
                principalId   = $PrincipalID
                principalType = $PrincipalType
                roleId        = $RoleID
            }
        )

        $v2Parameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource SpaceRoleAssignmentUpdate -SpaceId $SpaceID
        $v2Parameters['Method'] = 'Put'
        $v2Parameters['Body'] = $v2Content | ConvertTo-Json

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($v2Content | Out-String)"
        if ($PSCmdlet.ShouldProcess("Space $SpaceID role assignment for $PrincipalType $PrincipalID", "Set role to $RoleID")) {
            Invoke-Method @v2Parameters | ConvertTo-SpaceRoleAssignmentV2 -SpaceID $SpaceID
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
