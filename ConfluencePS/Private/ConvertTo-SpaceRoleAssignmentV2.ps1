function ConvertTo-SpaceRoleAssignmentV2 {
    <#
    .SYNOPSIS
    Converts a Confluence Cloud v2 space role assignment object to the
    ConfluencePS.SpaceRoleAssignment type.

    .DESCRIPTION
    Cloud v2 assigns a space role (for example Admin, Viewer) to a principal (a user or a
    group); this mirrors ConvertTo-SpacePermissionV2's nested principal/grant shape, since role
    assignment is the same kind of grant concept applied to roles instead of raw operations.

    This response shape is based on the same field conventions Cloud v2 uses across its other
    content-type resources and has not been live-verified against a Cloud tenant; see
    docs/api-contract-inventory.md.
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.SpaceRoleAssignment] )]
    param (
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        $InputObject,

        [Parameter()]
        [UInt64]
        $SpaceID
    )

    process {
        foreach ($object in $InputObject) {
            if ($null -eq $object) {
                continue
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Cloud v2 Object to SpaceRoleAssignment"

            [ConfluencePS.SpaceRoleAssignment](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                    @{Name = "spaceID"; Expression = { $SpaceID } },
                    @{Name = "principalType"; Expression = { $_.principal.type } },
                    @{Name = "principalID"; Expression = { $_.principal.id } },
                    @{Name = "roleID"; Expression = { $_.role.id } },
                    @{Name = "roleName"; Expression = { $_.role.name } }
                ))
        }
    }
}
