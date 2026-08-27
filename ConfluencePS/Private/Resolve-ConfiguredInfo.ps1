function Resolve-ConfiguredInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Object]
        $BaseUri
    )

    $metadata = @{
        Product            = $null
        DeploymentType     = $null
        AuthenticationType = $null
        CloudId            = $null
    }

    $baseUriValue = $BaseUri
    if ($BaseUri.PSObject.Properties['Uri']) {
        $baseUriValue = $BaseUri.Uri

        foreach ($propertyName in @('Product', 'DeploymentType', 'AuthenticationType', 'CloudId')) {
            if ($BaseUri.PSObject.Properties[$propertyName]) {
                $metadata[$propertyName] = $BaseUri.$propertyName
            }
        }

        if ($BaseUri.PSObject.Properties['Type'] -and -not [string]::IsNullOrWhiteSpace([string]$BaseUri.Type)) {
            $serverType = [string]$BaseUri.Type
            if ($serverType -ne 'Confluence') {
                throw "Set-ConfluenceInfo only accepts Confluence server configuration entries. The supplied configuration Type is '$serverType'."
            }
        }
    }

    [Uri]$resolvedBaseUri = $null
    if (-not [Uri]::TryCreate([string]$baseUriValue, [UriKind]::Absolute, [ref]$resolvedBaseUri)) {
        throw "BaseUri must be an absolute URI (e.g., https://confluence.example.com/wiki)"
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$metadata.Product) -and [string]$metadata.Product -ne 'Confluence') {
        throw "Set-ConfluenceInfo only accepts Confluence server configuration entries. The supplied configuration Product is '$($metadata.Product)'."
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$metadata.DeploymentType)) {
        switch -Regex ([string]$metadata.DeploymentType) {
            '^(?i:Cloud)$' {
                $metadata.DeploymentType = 'Cloud'
                break
            }
            '^(?i:DataCenter|Data Center)$' {
                $metadata.DeploymentType = 'DataCenter'
                break
            }
            '^(?i:Server)$' {
                $metadata.DeploymentType = 'Server'
                break
            }
            default {
                throw "Unsupported Confluence DeploymentType '$($metadata.DeploymentType)'. Use Cloud, DataCenter, or Server."
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$metadata.AuthenticationType) -and [string]$metadata.AuthenticationType -eq 'OAuth') {
        if (-not [string]::IsNullOrWhiteSpace([string]$metadata.DeploymentType) -and $metadata.DeploymentType -ne 'Cloud') {
            throw "Conflicting Confluence configuration metadata: AuthenticationType OAuth requires DeploymentType Cloud."
        }

        if ([string]::IsNullOrWhiteSpace([string]$metadata.DeploymentType)) {
            $metadata.DeploymentType = 'Cloud'
        }
    }

    if ($metadata.DeploymentType -eq 'Cloud' -and $resolvedBaseUri.Scheme -ne 'https') {
        throw "Confluence Cloud configuration requires an HTTPS BaseUri."
    }

    $apiUri = $null
    $uriHelper = Get-Command -Name ConvertTo-AtlassianUri -ErrorAction SilentlyContinue
    if ($uriHelper) {
        $uriParameters = @{
            Uri            = $resolvedBaseUri.AbsoluteUri
            Product        = 'Confluence'
            DeploymentType = if ($metadata.DeploymentType) { $metadata.DeploymentType } else { 'DataCenter' }
            Mode           = 'Api'
        }
        if ($metadata.CloudId) {
            $uriParameters.CloudId = $metadata.CloudId
        }

        $apiUri = ConvertTo-AtlassianUri @uriParameters
    }
    else {
        $base = $resolvedBaseUri.AbsoluteUri.TrimEnd('/')
        if ($metadata.DeploymentType -eq 'Cloud') {
            if (-not ([Uri]$base).AbsolutePath.TrimEnd('/').EndsWith('/wiki', [System.StringComparison]::OrdinalIgnoreCase)) {
                $base = "$base/wiki"
            }
        }

        $apiUri = [Uri]"$base/rest/api"
    }

    [PSCustomObject]@{
        BaseUri  = $resolvedBaseUri
        ApiUri   = [Uri]$apiUri
        Metadata = $metadata
    }
}
