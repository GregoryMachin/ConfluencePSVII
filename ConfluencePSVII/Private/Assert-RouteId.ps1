function Assert-RouteId {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [String]
        $Name,

        [Parameter()]
        [UInt64]
        $Value
    )

    if ($Value -eq 0) {
        throw "Confluence route value '$Name' must be a non-zero numeric identifier."
    }
}
