function ConvertTo-SpacePropertyV2 {
    <#
    .SYNOPSIS
    Converts a Confluence Cloud v2 space property object to the ConfluencePS.SpaceProperty type.

    .DESCRIPTION
    Cloud v2 space property responses do not echo back the owning space's ID, since the
    property is always read through a space-scoped route; -SpaceID supplies it from the
    caller's own context instead. `value` may be any JSON shape (string, number, object,
    array) and is passed through as-is, already converted from JSON by Invoke-ConfluenceMethod.

    This response shape is based on the same field conventions Cloud v2 uses across its other
    content-type resources and has not been live-verified against a Cloud tenant; see
    docs/api-contract-inventory.md.
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.SpaceProperty] )]
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

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Cloud v2 Object to SpaceProperty"

            [ConfluencePS.SpaceProperty](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                    @{Name = "id"; Expression = { if ($_.id) { [UInt64]$_.id } else { $null } } },
                    @{Name = "spaceID"; Expression = { $SpaceID } },
                    key,
                    value,
                    @{Name = "version"; Expression = {
                            if ($_.version) {
                                ConvertTo-VersionV2 $_.version
                            }
                            else { $null }
                        }
                    }
                ))
        }
    }
}
