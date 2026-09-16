function Set-SpaceProperty {
    <#
    .NOTES
    Cloud v2 only, same reasoning as Get-SpaceProperty. -Value is validated the same way
    New-SpaceProperty validates it (see Assert-PropertyKey/ConvertTo-PropertyJson): secrets are
    rejected and the serialized value is capped at 32,768 UTF-8 bytes.
    #>
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true
    )]
    [OutputType([ConfluencePS.SpaceProperty])]
    param (
        [Parameter( Mandatory = $true )]
        [Uri]$ApiUri,

        [Parameter( Mandatory = $true )]
        [Uri]$BaseUri,

        [Parameter( Mandatory = $false )]
        [PSCredential]$Credential,

        [Parameter( Mandatory = $false )]
        [String]
        $PersonalAccessToken,

        [Parameter( Mandatory = $false )]
        [ValidateNotNull()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $Certificate,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [UInt64]$SpaceID,

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [Alias('ID')]
        [UInt64]$PropertyID,

        [Parameter( Mandatory = $true )]
        [AllowNull()]
        [Object]$Value
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $authApiAndBaseUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter @('ApiUri', 'BaseUri')
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $originalProperty = Get-SpaceProperty -SpaceID $SpaceID -PropertyID $PropertyID @authApiAndBaseUri
        Assert-PropertyKey -Key $originalProperty.Key
        $versionNumber = ++$originalProperty.Version.Number
        $valueJson = ConvertTo-PropertyJson -Value $Value

        $v2Parameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource SpacePropertyById -SpaceId $SpaceID -PropertyId $PropertyID
        $v2Parameters['Method'] = 'Put'
        $v2Parameters['Body'] = "{`"key`":$($originalProperty.Key | ConvertTo-Json -Compress),`"value`":$valueJson,`"version`":{`"number`":$versionNumber}}"

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($v2Parameters['Body'])"
        if ($PSCmdlet.ShouldProcess("Space $SpaceID property $($originalProperty.Key)")) {
            Invoke-Method @v2Parameters | ConvertTo-SpacePropertyV2 -SpaceID $SpaceID
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
