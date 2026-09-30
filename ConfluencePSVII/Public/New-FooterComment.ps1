function New-FooterComment {
    [CmdletBinding(
        ConfirmImpact = 'Low',
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
            ParameterSetName = 'byParameters',
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [UInt64]$PageID,

        [Parameter(ParameterSetName = 'byParameters')]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [UInt64]$ParentCommentID,

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

        $resourceApi = "$ApiUri/content"

        $authAndApiUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter "ApiUri"

        # Cloud v2 opt-in (Task 51): -BaseUri + -DeploymentType Cloud route footer comment
        # creation to POST /footer-comments, using the same opt-in-parameter architecture
        # Phase 7/Task 50 established for pages, spaces, and blog posts.
        $useCloudV2 = ($DeploymentType -eq 'Cloud') -and $BaseUri
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($useCloudV2) {
            $pageIdValue = $null
            $parentCommentIdValue = $null
            $bodyValue = $null

            switch ($PsCmdlet.ParameterSetName) {
                "byObject" {
                    $pageIdValue = $InputObject.PageID
                    $parentCommentIdValue = $InputObject.ParentID
                    $bodyValue = $InputObject.Body
                }
                "byParameters" {
                    if ($Convert) {
                        Write-Verbose '[$($MyInvocation.MyCommand.Name)] -Convert flag active; converting content to Confluence storage format'
                        $Body = ConvertTo-StorageFormat -Content $Body @authAndApiUri
                    }

                    $pageIdValue = $PageID
                    $parentCommentIdValue = $ParentCommentID
                    $bodyValue = $Body
                }
            }

            $v2Content = [Ordered]@{
                pageId = [String]$pageIdValue
                body   = @{
                    representation = 'storage'
                    value          = $bodyValue
                }
            }
            if ($parentCommentIdValue) {
                $v2Content['parentCommentId'] = [String]$parentCommentIdValue
            }

            $v2Parameters = Copy-CommonParameter -InputObject $PSBoundParameters
            $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource FooterCommentCreate
            $v2Parameters['Method'] = 'Post'
            $v2Parameters['Body'] = $v2Content | ConvertTo-Json

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($v2Content | Out-String)"
            if ($PSCmdlet.ShouldProcess("Page $pageIdValue")) {
                Invoke-Method @v2Parameters | ConvertTo-CommentV2 -Type footer -BaseUri $BaseUri
            }
            return
        }

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Uri'] = $resourceApi
        $iwParameters['Method'] = 'Post'
        # No -OutputType: ConvertTo-Comment needs -Type footer, which automatic dispatch
        # cannot supply for the byObject path below; this command converts explicitly.

        $Content = [PSObject]@{
            type      = "comment"
            container = [PSObject]@{ id = ""; type = "page" }
            body      = [PSObject]@{
                storage = [PSObject]@{
                    representation = 'storage'
                }
            }
        }

        switch ($PsCmdlet.ParameterSetName) {
            "byObject" {
                $Content.container.id = "$($InputObject.PageID)"
                $Content.body.storage.value = $InputObject.Body
                if ($InputObject.ParentID) {
                    $Content | Add-Member -MemberType NoteProperty -Name 'ancestors' -Value @( @{ id = "$($InputObject.ParentID)" } )
                }
            }
            "byParameters" {
                if ($Convert) {
                    Write-Verbose '[$($MyInvocation.MyCommand.Name)] -Convert flag active; converting content to Confluence storage format'
                    $Body = ConvertTo-StorageFormat -Content $Body @authAndApiUri
                }

                $Content.container.id = "$PageID"
                $Content.body.storage.value = $Body
                if ($ParentCommentID) {
                    $Content | Add-Member -MemberType NoteProperty -Name 'ancestors' -Value @( @{ id = "$ParentCommentID" } )
                }
            }
        }

        $iwParameters["Body"] = $Content | ConvertTo-Json

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Content | Out-String)"
        If ($PSCmdlet.ShouldProcess("Page $($Content.container.id)")) {
            Invoke-Method @iwParameters | ConvertTo-Comment -Type footer
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
