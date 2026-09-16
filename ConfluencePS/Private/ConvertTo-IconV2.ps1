function ConvertTo-IconV2 {
    <#
    .SYNOPSIS
    Converts a Confluence Cloud v2 icon object to the existing ConfluencePS.Icon type.

    .DESCRIPTION
    Cloud v2 icon objects are download-link oriented (`{ path, apiDownloadLink }`) and
    typically omit the dimension/default fields v1 provided (`width`, `height`, `isDefault`).
    Whatever is present is used; missing fields fall back to their type defaults.
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.Icon] )]
    param (
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        $InputObject
    )

    process {
        foreach ($object in $InputObject) {
            if ($null -eq $object) {
                continue
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Cloud v2 Object to Icon"
            [ConfluencePS.Icon](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                    @{Name = "Path"; Expression = {
                            if ($_.path) { $_.path } else { $_.apiDownloadLink }
                        }
                    },
                    @{Name = "Width"; Expression = { if ($_.width) { [Int32]$_.width } else { 0 } } },
                    @{Name = "Height"; Expression = { if ($_.height) { [Int32]$_.height } else { 0 } } },
                    @{Name = "IsDefault"; Expression = { [Bool]$_.isDefault } }
                ))
        }
    }
}
