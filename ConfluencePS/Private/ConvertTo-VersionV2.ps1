function ConvertTo-VersionV2 {
    <#
    .SYNOPSIS
    Converts a Confluence Cloud v2 version object to the existing ConfluencePS.Version type.

    .DESCRIPTION
    Cloud v2 version objects (`{ authorId, createdAt, number, message, minorEdit }`) carry an
    account ID instead of an embedded author object and `createdAt` instead of `when`/
    `friendlyWhen`. FriendlyWhen has no v2 equivalent and is left unset.
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.Version] )]
    param (
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        $InputObject
    )

    process {
        foreach ($object in $InputObject) {
            if ($null -eq $object) {
                continue
            }

            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Cloud v2 Object to Version"
            [ConfluencePS.Version](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                    @{Name = "by"; Expression = { ConvertTo-UserV2 -AccountId $_.authorId } },
                    @{Name = "when"; Expression = { if ($_.createdAt) { [DateTime]$_.createdAt } else { $null } } },
                    number,
                    message,
                    @{Name = "minoredit"; Expression = { [Bool]$_.minorEdit } }
                ))
        }
    }
}
