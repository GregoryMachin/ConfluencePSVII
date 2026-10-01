function New-SpaceProperty {
    # Cloud v2 only, same reasoning as Get-SpaceProperty. -Key and -Value are validated by
    # Assert-PropertyKey/ConvertTo-PropertyJson before anything is sent: keys and nested value
    # keys are checked against a secret-name pattern and a small blocklist, and the serialized
    # value is capped at 32,768 UTF-8 bytes, matching Confluence Cloud's own limit and this
    # task's security review (properties must never be used to store secrets).
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true
    )]
    [OutputType([ConfluencePSVII.SpaceProperty])]
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

        [Parameter( Mandatory = $true )]
        [String]$Key,

        [Parameter( Mandatory = $true )]
        [AllowNull()]
        [Object]$Value
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        Assert-PropertyKey -Key $Key
        $valueJson = ConvertTo-PropertyJson -Value $Value

        $v2Parameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource SpacePropertyCollection -SpaceId $SpaceID
        $v2Parameters['Method'] = 'Post'
        $v2Parameters['Body'] = "{`"key`":$($Key | ConvertTo-Json -Compress),`"value`":$valueJson}"

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($v2Parameters['Body'])"
        if ($PSCmdlet.ShouldProcess("Space $SpaceID property $Key")) {
            Invoke-Method @v2Parameters | ConvertTo-SpacePropertyV2 -SpaceID $SpaceID
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
