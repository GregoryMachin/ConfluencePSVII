function ConvertTo-Comment {
    <#
    .SYNOPSIS
    Extracted the conversion to private function in order to have a single place to
    select the properties to use when casting to custom object type

    .DESCRIPTION
    Confluence v1 exposes comments as generic content items (`type=comment`); `-Type`
    records the caller's own "footer" or "inline" intent, since v1 does not distinguish
    between the two the way Cloud v2's dedicated resources do. `PageID` is read from the
    `container` field; `ParentID` is read from the last `ancestors` entry when present
    (a reply to another comment), and left at 0 for a top-level comment on the page.
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.Comment] )]
    param (
        # object to convert
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        $InputObject,

        [Parameter()]
        [ValidateSet('footer', 'inline')]
        [String]
        $Type = 'footer'
    )

    process {
        foreach ($object in $InputObject) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Object to Comment"
            [ConfluencePS.Comment](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                        id,
                    status,
                    @{Name = "body"; Expression = { $_.body.storage.value } },
                    @{Name = "version"; Expression = {
                            if ($_.version) {
                                ConvertTo-Version $_.version
                            }
                            else { $null }
                        }
                    },
                    @{Name = "pageId"; Expression = { if ($_.container.id) { [UInt64]$_.container.id } else { $null } } },
                    @{Name = "parentId"; Expression = {
                            if ($_.ancestors) {
                                [UInt64]($_.ancestors | Select-Object -Last 1).id
                            }
                            else { $null }
                        }
                    },
                    @{Name = "type"; Expression = { $Type } },
                    @{Name = "URL"; Expression = {
                            $base = $_._links.base
                            if (!($base)) { $base = $_._links.self -replace '\/rest.*', '' }
                            if ($_._links.webui) {
                                "{0}{1}" -f $base, $_._links.webui
                            }
                            else { $null }
                        }
                    },
                    @{Name = "ShortURL"; Expression = {
                            $base = $_._links.base
                            if (!($base)) { $base = $_._links.self -replace '\/rest.*', '' }
                            if ($_._links.tinyui) {
                                "{0}{1}" -f $base, $_._links.tinyui
                            }
                            else { $null }
                        }
                    }
                ))
        }
    }
}
