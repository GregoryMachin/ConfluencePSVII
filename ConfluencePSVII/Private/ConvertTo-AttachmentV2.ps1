function ConvertTo-AttachmentV2 {
    <#
    .SYNOPSIS
    Converts a Confluence Cloud v2 attachment object to the existing ConfluencePSVII.Attachment type.

    .DESCRIPTION
    Cloud v2 attachment objects carry `pageId` directly, so unlike the v1 adapter this never
    needs to parse `_expandable.container`. They also do not carry a space key at all
    (SpaceKey is left unset), and there is no `_links.base`, so `-BaseUri` supplies the origin
    used to build an absolute URL from `downloadLink`.
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePSVII.Attachment] )]
    param (
        [Parameter( ValueFromPipeline = $true )]
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

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Cloud v2 Object to Attachment"

            $linkBase = if ($BaseUri) { $BaseUri.AbsoluteUri.TrimEnd('/') } else { $null }

            [ConfluencePSVII.Attachment](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                    @{Name = "id"; Expression = {
                            if ($_.id) { [UInt64]($_.id -replace '^att', '') } else { $null }
                        }
                    },
                    status,
                    title,
                    @{Name = "filename"; Expression = {
                            '{0}_{1}' -f $_.pageId, $_.title | Remove-InvalidFileCharacter
                        }
                    },
                    @{Name = "mediatype"; Expression = { $_.mediaType } },
                    @{Name = "filesize"; Expression = {
                            if ($null -ne $_.fileSize) { [UInt32]$_.fileSize } else { $null }
                        }
                    },
                    comment,
                    @{Name = "spacekey"; Expression = { $null } },
                    @{Name = "pageid"; Expression = {
                            if ($_.pageId) { [UInt64]$_.pageId } else { $null }
                        }
                    },
                    @{Name = "version"; Expression = {
                            if ($_.version) {
                                ConvertTo-VersionV2 $_.version
                            }
                            else { $null }
                        }
                    },
                    @{Name = "URL"; Expression = {
                            if ($linkBase -and $_.downloadLink) {
                                "{0}{1}" -f $linkBase, $_.downloadLink
                            }
                            else { $null }
                        }
                    }
                ))
        }
    }
}
