function ConvertTo-InlineTaskV2 {
    <#
    .SYNOPSIS
    Converts a Confluence Cloud v2 task object to the ConfluencePSVII.InlineTask type.

    .DESCRIPTION
    Cloud v2 inline tasks identify people only by opaque account ID (`createdBy`,
    `assignedTo`, `completedBy`), converted through the existing ConvertTo-UserV2, which
    already returns $null for a missing/empty account ID -- a task's `assignedTo` and
    `completedBy` are legitimately absent until someone claims or completes it. `dueAt` and
    `completedAt` are likewise optional and left unset when absent.

    This response shape is based on the same field conventions Cloud v2 uses across its other
    content-type resources (pages, databases, folders, whiteboards) and has not been
    live-verified against a Cloud tenant; see docs/api-contract-inventory.md.
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePSVII.InlineTask] )]
    param (
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        $InputObject
    )

    process {
        foreach ($object in $InputObject) {
            if ($null -eq $object) {
                continue
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Cloud v2 Object to InlineTask"

            [ConfluencePSVII.InlineTask](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                    @{Name = "id"; Expression = { if ($_.id) { [UInt64]$_.id } else { $null } } },
                    @{Name = "localId"; Expression = { if ($_.localId) { [UInt64]$_.localId } else { $null } } },
                    @{Name = "pageId"; Expression = { if ($_.pageId) { [UInt64]$_.pageId } else { $null } } },
                    status,
                    @{Name = "body"; Expression = { $_.body.storage.value } },
                    @{Name = "createdBy"; Expression = { ConvertTo-UserV2 -AccountId $_.createdBy } },
                    @{Name = "assignedTo"; Expression = { ConvertTo-UserV2 -AccountId $_.assignedTo } },
                    @{Name = "completedBy"; Expression = { ConvertTo-UserV2 -AccountId $_.completedBy } },
                    @{Name = "createdAt"; Expression = { if ($_.createdAt) { [DateTime]$_.createdAt } else { $null } } },
                    @{Name = "dueAt"; Expression = { if ($_.dueAt) { [DateTime]$_.dueAt } else { $null } } },
                    @{Name = "completedAt"; Expression = { if ($_.completedAt) { [DateTime]$_.completedAt } else { $null } } },
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
