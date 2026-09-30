function Set-FooterComment {
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = 'byParameters'
    )]
    [OutputType([ConfluencePSVII.Comment])]
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
        [ConfluencePSVII.Comment]$InputObject,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
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

        # Cloud v2 opt-in (Task 51): -BaseUri + -DeploymentType Cloud route footer comment
        # updates to PUT /footer-comments/{id}. The current version number is read first and
        # incremented, so a conflicting concurrent edit is rejected by Confluence's own
        # optimistic concurrency check on the submitted version number, the same pattern
        # Set-Page/Set-BlogPost use.
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
                    $originalComment = Get-FooterComment -CommentID $CommentID @authApiAndBaseUri
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
            $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource FooterCommentUpdate -CommentId $commentIdV2
            $v2Parameters['Method'] = 'Put'
            $v2Parameters['Body'] = $v2Content | ConvertTo-Json

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($v2Content | Out-String)"
            if ($PSCmdlet.ShouldProcess("Comment $commentIdV2")) {
                Invoke-Method @v2Parameters | ConvertTo-CommentV2 -Type footer -BaseUri $BaseUri
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
                $originalComment = Get-FooterComment -CommentID $CommentID @authAndApiUri

                $Content.version.number = ++$originalComment.Version.Number
                $Content.body.storage.value = $Body
            }
        }

        $iwParameters["Body"] = $Content | ConvertTo-Json

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Content | Out-String)"
        If ($PSCmdlet.ShouldProcess("Comment $($iwParameters['Uri'])")) {
            Invoke-Method @iwParameters | ConvertTo-Comment -Type footer
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
