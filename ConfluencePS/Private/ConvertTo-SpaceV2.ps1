function ConvertTo-SpaceV2 {
    <#
    .SYNOPSIS
    Converts a Confluence Cloud v2 space object to the existing ConfluencePS.Space type.

    .DESCRIPTION
    Cloud v2 space objects reference their homepage only by `homepageId` (not an embedded page
    object), so Homepage is populated with a partial ConfluencePS.Page carrying only that ID;
    callers that need the full homepage must resolve it separately. Description is read from
    the plain-text representation, matching the v1 adapter's behavior.
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.Space] )]
    param (
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        $InputObject
    )

    process {
        foreach ($object in $InputObject) {
            if ($null -eq $object) {
                continue
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Cloud v2 Object to Space"
            [ConfluencePS.Space](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                    @{Name = "id"; Expression = { if ($_.id) { [UInt64]$_.id } else { $null } } },
                    key,
                    name,
                    @{Name = "description"; Expression = { $_.description.plain.value } },
                    @{Name = "Icon"; Expression = {
                            if ($_.icon) {
                                ConvertTo-IconV2 $_.icon
                            }
                            else { $null }
                        }
                    },
                    type,
                    @{Name = "Homepage"; Expression = {
                            if ($_.homepageId) {
                                [ConfluencePS.Page]@{ ID = [UInt64]$_.homepageId }
                            }
                            else { $null }
                        }
                    }
                ))
        }
    }
}
