function Assert-PropertyDataKey {
    <#
    .SYNOPSIS
    Validates one key, at any nesting depth, inside a space property's value.

    .DESCRIPTION
    Rejects prototype-pollution-shaped keys and keys that look like they are meant to carry a
    secret (password, token, credential, API key, ...), mirroring JiraPSVII's
    Test-JiraEntityPropertyDataKey. Applied both to the property's own key (via
    Assert-PropertyKey) and to every object key found while walking a property's value (via
    ConvertTo-SafePropertyValue).
    #>
    [CmdletBinding()]
    param(
        [Parameter( Mandatory )]
        [String]
        $Key,

        [Parameter( Mandatory )]
        [String]
        $Path
    )

    if ($Key -in @('__proto__', 'prototype', 'constructor')) {
        throw [System.ArgumentException]::new("Property data key '$Path.$Key' is not allowed.", 'Value')
    }
    if ($Key -match '(?i)(password|secret|token|credential|authorization|private.?key|api.?key)') {
        throw [System.ArgumentException]::new("Property data key '$Path.$Key' appears to contain a secret and is not allowed.", 'Value')
    }
}
