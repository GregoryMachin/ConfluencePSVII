function Assert-PropertyKey {
    <#
    .SYNOPSIS
    Validates a space property's own key.

    .DESCRIPTION
    Mirrors JiraPSVII's entity-property key policy (Test-JiraEntityPropertyKey): keys must be a
    short, plain identifier, and must not look like they are meant to carry a secret --
    property values are stored in Confluence, not a secret store, and the security review for
    this feature requires that secrets never be persisted through it.
    #>
    [CmdletBinding()]
    param(
        [Parameter( Mandatory )]
        [String]
        $Key
    )

    if ($Key -notmatch '^[A-Za-z0-9][A-Za-z0-9._:-]{0,254}$') {
        throw [System.ArgumentException]::new('Property keys must be 1-255 characters and contain only letters, digits, dots, underscores, colons, or hyphens.', 'Key')
    }
    Assert-PropertyDataKey -Key $Key -Path 'Key'
}
