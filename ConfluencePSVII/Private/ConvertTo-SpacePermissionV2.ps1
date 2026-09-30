function ConvertTo-SpacePermissionV2 {
    <#
    .SYNOPSIS
    Converts a Confluence Cloud v2 space permission object to the ConfluencePSVII.SpacePermission type.

    .DESCRIPTION
    Cloud v2 grants a permission to a principal (a user, a group, or a space role) and an
    operation (a key plus the content-type the operation applies to); this is a read-only view
    of currently effective grants, not a mutation surface -- Cloud v2 does not expose a way to
    add or remove an individual permission grant directly, only space role assignments (see
    ConvertTo-SpaceRoleAssignmentV2).

    This response shape is based on the same field conventions Cloud v2 uses across its other
    content-type resources and has not been live-verified against a Cloud tenant; see
    docs/api-contract-inventory.md.
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePSVII.SpacePermission] )]
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

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Cloud v2 Object to SpacePermission"

            [ConfluencePSVII.SpacePermission](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                    @{Name = "id"; Expression = { if ($_.id) { [UInt64]$_.id } else { $null } } },
                    @{Name = "spaceID"; Expression = { $SpaceID } },
                    @{Name = "principalType"; Expression = { $_.principal.type } },
                    @{Name = "principalID"; Expression = { $_.principal.id } },
                    @{Name = "operationKey"; Expression = { $_.operation.key } },
                    @{Name = "operationTargetType"; Expression = { $_.operation.targetType } }
                ))
        }
    }
}
