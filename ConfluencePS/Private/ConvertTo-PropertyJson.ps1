function ConvertTo-PropertyJson {
    <#
    .SYNOPSIS
    Validates and serializes a proposed space property value for the request body.

    .DESCRIPTION
    Mirrors JiraPS's ConvertTo-JiraPropertyJson: rejects a null value outright, runs the value
    through ConvertTo-SafePropertyValue, serializes it, and enforces Confluence Cloud's 32,768
    UTF-8 byte limit on a property's serialized value before ever sending it.
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter( Mandatory )]
        [AllowNull()]
        [Object]
        $Value
    )

    if ($null -eq $Value) {
        throw [System.ArgumentException]::new('Property values must be a non-null JSON primitive, object, or array.', 'Value')
    }

    $safeValue = ConvertTo-SafePropertyValue -Value $Value -Path 'Value'
    $json = ConvertTo-Json -InputObject $safeValue -Depth 20 -Compress
    if ([System.Text.Encoding]::UTF8.GetByteCount($json) -gt 32768) {
        throw [System.ArgumentOutOfRangeException]::new('Value', 'Property values must not exceed 32,768 UTF-8 bytes when serialized as JSON.')
    }
    $json
}
