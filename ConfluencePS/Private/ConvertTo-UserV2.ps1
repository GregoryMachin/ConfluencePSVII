function ConvertTo-UserV2 {
    <#
    .SYNOPSIS
    Wraps a Confluence Cloud v2 account ID in the existing ConfluencePS.User type.

    .DESCRIPTION
    Cloud v2 responses identify people only by an opaque `accountId` string (`authorId`,
    `ownerId`, and similar fields); they never embed a full user object the way v1 responses
    did under `by`. There is no dedicated AccountId slot on the public ConfluencePS.User type,
    so the account ID is stored in UserKey and every other property is left unset, consistent
    with the migration decision to stop assuming legacy username/user-key identity on Cloud.
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePS.User] )]
    param (
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        [AllowNull()]
        [String]
        $AccountId
    )

    process {
        if ([String]::IsNullOrEmpty($AccountId)) {
            return $null
        }

        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Cloud v2 account ID to User"
        [ConfluencePS.User]@{
            UserKey = $AccountId
        }
    }
}
