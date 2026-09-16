function Set-InlineComment {
    <#
    .NOTES
    Updating a comment's body needs no text-selection anchor, so unlike New-InlineComment
    this command works on v1/Data Center as well as Cloud v2 -- it is just a generic
    comment-body update either way.
    #>
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = 'byParameters'
    )]
    [OutputType([ConfluencePS.Comment])]
    param (
        [Parameter( Mandatory = $true )]
        [Uri]$ApiUri,

        [Parameter( Mandatory = $false )]
        [Uri]$BaseUri,

        [Parameter( Mandatory = $false )]
        [ValidateSet('', 'Cloud', 'DataCenter', 'Server')]
        [String]$DeploymentType,

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
            ValueFromPipeline = $true,
            ParameterSetName = 'byObject'
        )]
        [ConfluencePS.Comment]$InputObject,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byParameters'
        )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [Alias('ID')]
        [UInt64]$CommentID,

        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'byParameters'
        )]
        [String]$Body,

        [Parameter(ParameterSetName = 'byParameters')]
        [Switch]$Convert
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$ApiUri/content/{0}"

        $authAndApiUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter "ApiUri"
        $authApiAndBaseUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter @('ApiUri', 'BaseUri', 'DeploymentType')
        if ($Convert) {
            Write-Verbose '[$($MyInvocation.MyCommand.Name)] -Convert flag active; converting content to Confluence storage format'
            $Body = ConvertTo-StorageFormat -Content $Body @authAndApiUri
        }

        $useCloudV2 = ($DeploymentType -eq 'Cloud') -and $BaseUri
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($useCloudV2) {
            $commentIdV2 = $null
            $versionNumber = $null
            $bodyValue = $null

            switch ($PsCmdlet.ParameterSetName) {
                "byObject" {
                    $commentIdV2 = $InputObject.ID
                    $versionNumber = ++$InputObject.Version.Number
                    $bodyValue = $InputObject.Body
                }
                "byParameters" {
                    $commentIdV2 = $CommentID
                    $originalComment = Get-InlineComment -CommentID $CommentID @authApiAndBaseUri
                    $versionNumber = ++$originalComment.Version.Number
                    $bodyValue = $Body
                }
            }

            $v2Content = [Ordered]@{
                id      = [String]$commentIdV2
                body    = @{
                    representation = 'storage'
                    value          = $bodyValue
                }
                version = @{
                    number = $versionNumber
                }
            }

            $v2Parameters = Copy-CommonParameter -InputObject $PSBoundParameters
            $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource InlineCommentUpdate -CommentId $commentIdV2
            $v2Parameters['Method'] = 'Put'
            $v2Parameters['Body'] = $v2Content | ConvertTo-Json

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($v2Content | Out-String)"
            if ($PSCmdlet.ShouldProcess("Comment $commentIdV2")) {
                Invoke-Method @v2Parameters | ConvertTo-CommentV2 -Type inline -BaseUri $BaseUri
            }
            return
        }

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Put'

        $Content = [PSObject]@{
            type    = "comment"
            body    = [PSObject]@{
                storage = [PSObject]@{
                    value          = ""
                    representation = 'storage'
                }
            }
            version = [PSObject]@{
                number = 0
            }
        }

        switch ($PsCmdlet.ParameterSetName) {
            "byObject" {
                $iwParameters["Uri"] = $resourceApi -f $InputObject.ID
                $Content.version.number = ++$InputObject.Version.Number
                $Content.body.storage.value = $InputObject.Body
            }
            "byParameters" {
                $iwParameters["Uri"] = $resourceApi -f $CommentID
                $originalComment = Get-InlineComment -CommentID $CommentID @authAndApiUri

                $Content.version.number = ++$originalComment.Version.Number
                $Content.body.storage.value = $Body
            }
        }

        $iwParameters["Body"] = $Content | ConvertTo-Json

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Content | Out-String)"
        If ($PSCmdlet.ShouldProcess("Comment $($iwParameters['Uri'])")) {
            Invoke-Method @iwParameters | ConvertTo-Comment -Type inline
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
