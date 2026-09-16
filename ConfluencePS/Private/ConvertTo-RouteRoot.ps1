function ConvertTo-RouteRoot {
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory)]
        [Uri]
        $BaseUri,

        [Parameter(Mandatory)]
        [String]
        $DeploymentType
    )

    # GetLeftPart(Path) deliberately drops any query string or fragment carried by an
    # absolute-link-shaped BaseUri; routes are built from fixed templates only.
    $root = $BaseUri.GetLeftPart([UriPartial]::Path).TrimEnd('/')

    if ($DeploymentType -eq 'Cloud' -and $root -notmatch '/wiki$') {
        $root = "$root/wiki"
    }

    return $root
}
