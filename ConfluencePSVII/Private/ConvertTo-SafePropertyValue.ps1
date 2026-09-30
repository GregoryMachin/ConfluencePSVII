function ConvertTo-SafePropertyValue {
    <#
    .SYNOPSIS
    Recursively walks a proposed space property value, rejecting anything unsafe to store.

    .DESCRIPTION
    Mirrors JiraPSVII's ConvertTo-JiraSafePropertyValue: rejects credentials, secure strings, and
    script blocks outright; validates every object key found at any nesting depth via
    Assert-PropertyDataKey; and returns a plain, JSON-serializable copy (ordered hashtables and
    arrays) rather than passing PSCustomObject/hashtable input straight through.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [Object]
        $Value,

        [Parameter( Mandatory )]
        [String]
        $Path,

        [Switch]
        $AllowNull
    )

    if ($null -eq $Value) {
        if ($AllowNull) { return $null }
        throw [System.ArgumentException]::new("Property value '$Path' must not be null.", 'Value')
    }
    if ($Value -is [ScriptBlock] -or $Value -is [PSCredential] -or $Value -is [System.Security.SecureString]) {
        throw [System.ArgumentException]::new("Property value '$Path' must not contain credentials, secure strings, or script blocks.", 'Value')
    }
    if ($Value -is [String] -or $Value -is [ValueType]) { return $Value }

    if ($Value -is [System.Collections.IDictionary]) {
        $safe = [Ordered]@{}
        foreach ($entry in $Value.GetEnumerator()) {
            $key = [String]$entry.Key
            Assert-PropertyDataKey -Key $key -Path $Path
            $safe[$key] = ConvertTo-SafePropertyValue -Value $entry.Value -Path "$Path.$key" -AllowNull
        }
        return $safe
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        $safe = [System.Collections.Generic.List[Object]]::new()
        $index = 0
        foreach ($entry in $Value) {
            $safe.Add((ConvertTo-SafePropertyValue -Value $entry -Path "$Path[$index]" -AllowNull))
            $index++
        }
        return @($safe)
    }

    $safe = [Ordered]@{}
    foreach ($property in $Value.PSObject.Properties.Where({ $_.MemberType -eq 'NoteProperty' })) {
        Assert-PropertyDataKey -Key $property.Name -Path $Path
        $safe[$property.Name] = ConvertTo-SafePropertyValue -Value $property.Value -Path "$Path.$($property.Name)" -AllowNull
    }
    if ($safe.Count -eq 0) {
        throw [System.ArgumentException]::new("Property value '$Path' must be JSON-serializable data.", 'Value')
    }
    $safe
}
