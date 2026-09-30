function ConvertTo-CommentV2 {
    <#
    .SYNOPSIS
    Converts a Confluence Cloud v2 footer/inline comment object to the existing
    ConfluencePSVII.Comment type.

    .DESCRIPTION
    Cloud v2 comment objects carry their container as `pageId` or `blogPostId` (never both)
    and their reply parent, if any, as `parentCommentId`; `-Type` records the caller's own
    "footer" or "inline" intent, since the object itself does not restate which collection it
    came from. The body is nested under the requested representation (`body.storage`,
    `body.atlas_doc_format`, ...), and there is no `_links.base` to combine with
    `_links.webui`/`_links.tinyui` for absolute URLs; `-BaseUri` supplies that base when the
    response itself does not.
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePSVII.Comment] )]
    param (
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        $InputObject,

        [Parameter()]
        [ValidateSet('footer', 'inline')]
        [String]
        $Type = 'footer',

        [Parameter()]
        [Uri]
        $BaseUri
    )

    process {
        foreach ($object in $InputObject) {
            if ($null -eq $object) {
                continue
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Cloud v2 Object to Comment"

            $linkBase = if ($object._links.base) { $object._links.base } elseif ($BaseUri) { $BaseUri.AbsoluteUri.TrimEnd('/') } else { $null }

            [ConfluencePSVII.Comment](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                    @{Name = "id"; Expression = { if ($_.id) { [UInt64]$_.id } else { $null } } },
                    status,
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
                    @{Name = "pageId"; Expression = {
                            if ($_.pageId) { [UInt64]$_.pageId }
                            elseif ($_.blogPostId) { [UInt64]$_.blogPostId }
                            else { $null }
                        }
                    },
                    @{Name = "parentId"; Expression = { if ($_.parentCommentId) { [UInt64]$_.parentCommentId } else { $null } } },
                    @{Name = "type"; Expression = { $Type } },
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
