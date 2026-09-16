function ConvertTo-BlogPostV2 {
    <#
    .SYNOPSIS
    Converts a Confluence Cloud v2 blog post object to the existing ConfluencePS.BlogPost type.

    .DESCRIPTION
    Cloud v2 blog post objects differ structurally from v1: the ID is a numeric string, the
    space is referenced only by `spaceId` (not an embedded space object), the body is nested
    under the requested representation (`body.storage`, `body.atlas_doc_format`, ...), and
    there is no `_links.base` to combine with `_links.webui`/`_links.tinyui` for absolute
    URLs. `-BaseUri` supplies that base when the response itself does not.

    Only known content representations are read from `body`; an unrecognized or missing
    representation leaves Body unset rather than guessing at its shape.
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.BlogPost] )]
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

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Cloud v2 Object to BlogPost"

            $linkBase = if ($object._links.base) { $object._links.base } elseif ($BaseUri) { $BaseUri.AbsoluteUri.TrimEnd('/') } else { $null }

            [ConfluencePS.BlogPost](ConvertTo-Hashtable -InputObject ($object | Select-Object `
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
