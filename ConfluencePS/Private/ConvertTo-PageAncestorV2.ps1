function ConvertTo-PageAncestorV2 {
    <#
    .SYNOPSIS
    Converts a Confluence Cloud v2 ancestor entry to the existing ConfluencePS.Page type.

    .DESCRIPTION
    Cloud v2's dedicated ancestors endpoint returns the same minimal shape (`id`, `status`,
    `title`) as v1's `ancestors` expand does, just with a numeric-string id, so this mirrors
    ConvertTo-PageAncestor rather than the full ConvertTo-PageV2 conversion.
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.Page] )]
    param (
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        $InputObject
    )

    process {
        foreach ($object in $InputObject) {
            if ($null -eq $object) {
                continue
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Cloud v2 Object to Page (Ancestor)"
            [ConfluencePS.Page](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                    @{Name = "id"; Expression = { if ($_.id) { [UInt64]$_.id } else { $null } } },
                    status,
                    title
                ))
        }
    }
}
