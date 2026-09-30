function ConvertTo-PageV2 {
    <#
    .SYNOPSIS
    Converts a Confluence Cloud v2 page object to the existing ConfluencePSVII.Page type.

    .DESCRIPTION
    Cloud v2 page objects differ structurally from v1: the ID is a numeric string, the space
    is referenced only by `spaceId` (not an embedded space object), the body is nested under
    the requested representation (`body.storage`, `body.atlas_doc_format`, ...), ancestors are
    not included at all (they require a separate `/ancestors` request), and there is no
    `_links.base` to combine with `_links.webui`/`_links.tinyui` for absolute URLs. `-BaseUri`
    supplies that base when the response itself does not.

    Only known content representations are read from `body`; an unrecognized or missing
    representation leaves Body unset rather than guessing at its shape.
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePSVII.Page] )]
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

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Cloud v2 Object to Page"

            $linkBase = if ($object._links.base) { $object._links.base } elseif ($BaseUri) { $BaseUri.AbsoluteUri.TrimEnd('/') } else { $null }

            [ConfluencePSVII.Page](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                    @{Name = "id"; Expression = { if ($_.id) { [UInt64]$_.id } else { $null } } },
                    status,
                    title,
                    @{Name = "space"; Expression = {
                            if ($_.spaceId) {
                                [ConfluencePSVII.Space]@{ Id = [UInt64]$_.spaceId }
                            }
                            else { $null }
                        }
                    },
                    @{Name = "version"; Expression = {
                            if ($_.version) {
                                ConvertTo-VersionV2 $_.version
                            }
                            else { $null }
                        }
                    },
                    @{Name = "body"; Expression = {
                            foreach ($representation in @('storage', 'view', 'atlas_doc_format')) {
                                if ($_.body.$representation.value) {
                                    return $_.body.$representation.value
                                }
                            }
                            return $null
                        }
                    },
                    @{Name = "ancestors"; Expression = { $null } },
                    @{Name = "URL"; Expression = {
                            if ($linkBase -and $_._links.webui) {
                                "{0}{1}" -f $linkBase, $_._links.webui
                            }
                            else { $null }
                        }
                    },
                    @{Name = "ShortURL"; Expression = {
                            if ($linkBase -and $_._links.tinyui) {
                                "{0}{1}" -f $linkBase, $_._links.tinyui
                            }
                            else { $null }
                        }
                    }
                ))
        }
    }
}
