function ConvertTo-DatabaseV2 {
    <#
    .SYNOPSIS
    Converts a Confluence Cloud v2 database object to the ConfluencePS.Database type.

    .DESCRIPTION
    Cloud v2 databases are a Smart Links/Jira-style embedded database view, not a text
    content type -- there is no `body`/storage representation to convert, only stable
    metadata (id, status, title, spaceId, parentId, version). This mirrors the minimal-field
    approach ConvertTo-PageV2 uses for Space/Version, without a Body property at all.

    This response shape is based on the same field conventions Cloud v2 uses across its other
    content-type resources (pages, folders, whiteboards) and has not been live-verified
    against a Cloud tenant; see docs/api-contract-inventory.md.
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.Database] )]
    param (
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        $InputObject,

        [Parameter()]
        [Uri]
        $BaseUri
    )

    process {
        foreach ($object in $InputObject) {
            if ($null -eq $object) {
                continue
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Cloud v2 Object to Database"

            $linkBase = if ($object._links.base) { $object._links.base } elseif ($BaseUri) { $BaseUri.AbsoluteUri.TrimEnd('/') } else { $null }

            [ConfluencePS.Database](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                    @{Name = "id"; Expression = { if ($_.id) { [UInt64]$_.id } else { $null } } },
                    status,
                    title,
                    @{Name = "space"; Expression = {
                            if ($_.spaceId) {
                                [ConfluencePS.Space]@{ Id = [UInt64]$_.spaceId }
                            }
                            else { $null }
                        }
                    },
                    @{Name = "parentId"; Expression = { if ($_.parentId) { [UInt64]$_.parentId } else { $null } } },
                    @{Name = "version"; Expression = {
                            if ($_.version) {
                                ConvertTo-VersionV2 $_.version
                            }
                            else { $null }
                        }
                    },
                    @{Name = "URL"; Expression = {
                            if ($linkBase -and $_._links.webui) {
                                "{0}{1}" -f $linkBase, $_._links.webui
                            }
                            else { $null }
                        }
                    }
                ))
        }
    }
}
