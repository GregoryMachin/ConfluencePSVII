function Assert-RouteKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]
        $Name,

        [Parameter()]
        [String]
        $Value
    )

    if ([String]::IsNullOrWhiteSpace($Value)) {
        throw "Confluence route value '$Name' must not be empty."
    }

    if ($Value -match '[\\/\s]' -or $Value -match '\.\.') {
        throw "Confluence route value '$Name' contains characters that are not allowed in a URI path segment."
    }
}
