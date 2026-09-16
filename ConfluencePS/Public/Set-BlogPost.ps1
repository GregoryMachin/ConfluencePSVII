function Set-BlogPost {
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = 'byParameters'
    )]
    [OutputType([ConfluencePS.BlogPost])]
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
        [ConfluencePS.BlogPost]$InputObject,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byParameters'
        )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [Alias('ID')]
        [UInt64]$BlogPostID,

        [Parameter(ParameterSetName = 'byParameters')]
        [ValidateNotNullOrEmpty()]
        [String]$Title,

        [Parameter(ParameterSetName = 'byParameters')]
        [String]$Body,

        [Parameter(ParameterSetName = 'byParameters')]
        [Switch]$Convert
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$ApiUri/content/{0}"

        $authAndApiUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter "ApiUri"
        # Same, but also forwards -BaseUri/-DeploymentType for the internal Get-BlogPost call
        # so it can use Cloud v2 routing; ConvertTo-StorageFormat does not accept them.
        $authApiAndBaseUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter @('ApiUri', 'BaseUri', 'DeploymentType')
        # If -Convert is flagged, call ConvertTo-ConfluenceStorageFormat against the -Body
        if ($Convert) {
            Write-Verbose '[$($MyInvocation.MyCommand.Name)] -Convert flag active; converting content to Confluence storage format'
            $Body = ConvertTo-StorageFormat -Content $Body @authAndApiUri
        }

        # Cloud v2 opt-in (Task 50): -BaseUri + -DeploymentType Cloud route blog post updates
        # to PUT /blogposts/{id}. The current version number is still read first and
        # incremented, so a conflicting concurrent edit is rejected by Confluence's own
        # optimistic concurrency check on the submitted version number, the same pattern
        # Set-Page uses (Task 48).
        $useCloudV2 = ($DeploymentType -eq 'Cloud') -and $BaseUri
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($useCloudV2) {
            $blogPostIdV2 = $null
            $versionNumber = $null
            $versionMessage = $null
            $titleValue = $null
            $bodyValue = $null

            switch ($PsCmdlet.ParameterSetName) {
                "byObject" {
                    $blogPostIdV2 = $InputObject.ID
                    $versionNumber = ++$InputObject.Version.Number
                    if ($null -ne $InputObject.Version.Message) {
                        $versionMessage = $InputObject.Version.Message
                    }
                    $titleValue = $InputObject.Title
                    $bodyValue = $InputObject.Body
                }
                "byParameters" {
                    $blogPostIdV2 = $BlogPostID
                    $originalBlogPost = Get-BlogPost -BlogPostID $BlogPostID @authApiAndBaseUri

                    $versionNumber = ++$originalBlogPost.Version.Number
                    $titleValue = if ($Title) { $Title } else { $originalBlogPost.Title }
                    $bodyValue = if ($PSBoundParameters.Keys -contains "Body") { $Body } else { $originalBlogPost.Body }
                }
            }

            $v2Content = [Ordered]@{
                id      = [String]$blogPostIdV2
                status  = 'current'
                title   = $titleValue
                body    = @{
                    representation = 'storage'
                    value          = $bodyValue
                }
                version = @{
                    number = $versionNumber
                }
            }
            if ($versionMessage) {
                $v2Content.version['message'] = $versionMessage
            }

            $v2Parameters = Copy-CommonParameter -InputObject $PSBoundParameters
            $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource BlogPostUpdate -PageId $blogPostIdV2
            $v2Parameters['Method'] = 'Put'
            $v2Parameters['Body'] = $v2Content | ConvertTo-Json

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($v2Content | Out-String)"
            if ($PSCmdlet.ShouldProcess("BlogPost $titleValue")) {
                Invoke-Method @v2Parameters | ConvertTo-BlogPostV2 -BaseUri $BaseUri
            }
            return
        }

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Put'
        $iwParameters['OutputType'] = [ConfluencePS.BlogPost]

        $Content = [PSObject]@{
            type    = "blogpost"
            title   = ""
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
                if ($null -ne $InputObject.Version.Message) {
                    $Content.version.message = $InputObject.Version.Message
                }
                $Content.title = $InputObject.Title
                $Content.body.storage.value = $InputObject.Body
            }
            "byParameters" {
                $iwParameters["Uri"] = $resourceApi -f $BlogPostID
                $originalBlogPost = Get-BlogPost -BlogPostID $BlogPostID @authAndApiUri

                $Content.version.number = ++$originalBlogPost.Version.Number
                if ($Title) { $Content.title = $Title }
                else { $Content.title = $originalBlogPost.Title }
                # $Body might be empty
                if ($PSBoundParameters.Keys -contains "Body") {
                    $Content.body.storage.value = $Body
                }
                else {
                    $Content.body.storage.value = $originalBlogPost.Body
                }
            }
        }

        $iwParameters["Body"] = $Content | ConvertTo-Json

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Content | Out-String)"
        If ($PSCmdlet.ShouldProcess("BlogPost $($Content.title)")) {
            Invoke-Method @iwParameters
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
