function Set-Page {
    [CmdletBinding(
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = 'byParameters'
    )]
    [OutputType([ConfluencePS.Page])]
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
        [ConfluencePS.Page]$InputObject,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byParameters'
        )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [Alias('ID')]
        [UInt64]$PageID,

        [Parameter(ParameterSetName = 'byParameters')]
        [ValidateNotNullOrEmpty()]
        [String]$Title,

        [Parameter(ParameterSetName = 'byParameters')]
        [String]$Body,

        [Parameter(ParameterSetName = 'byParameters')]
        [Switch]$Convert,

        [Parameter(ParameterSetName = 'byParameters')]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [UInt64]$ParentID,

        [Parameter(ParameterSetName = 'byParameters')]
        [ConfluencePS.Page]$Parent
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$ApiUri/content/{0}"

        $authAndApiUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter "ApiUri"
        # Same, but also forwards -BaseUri/-DeploymentType for the internal Get-Page call so
        # it can use Cloud v2 routing; ConvertTo-StorageFormat does not accept them.
        $authApiAndBaseUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter @('ApiUri', 'BaseUri', 'DeploymentType')
        # If -Convert is flagged, call ConvertTo-ConfluenceStorageFormat against the -Body
        if ($Convert) {
            Write-Verbose '[$($MyInvocation.MyCommand.Name)] -Convert flag active; converting content to Confluence storage format'
            $Body = ConvertTo-StorageFormat -Content $Body @authAndApiUri
        }

        # Cloud v2 opt-in (Task 48): -BaseUri + -DeploymentType Cloud route page updates to
        # PUT /pages/{id}. The current version number is still read first and incremented,
        # so a conflicting concurrent edit is rejected by Confluence's own optimistic
        # concurrency check on the submitted version number, the same as the v1 path relies on.
        $useCloudV2 = ($DeploymentType -eq 'Cloud') -and $BaseUri
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($useCloudV2) {
            $pageIdV2 = $null
            $versionNumber = $null
            $versionMessage = $null
            $titleValue = $null
            $bodyValue = $null
            $parentIdV2 = $null

            switch ($PsCmdlet.ParameterSetName) {
                "byObject" {
                    $pageIdV2 = $InputObject.ID
                    $versionNumber = ++$InputObject.Version.Number
                    if ($null -ne $InputObject.Version.Message) {
                        $versionMessage = $InputObject.Version.Message
                    }
                    $titleValue = $InputObject.Title
                    $bodyValue = $InputObject.Body
                }
                "byParameters" {
                    $pageIdV2 = $PageID
                    $originalPage = Get-Page -PageID $PageID @authApiAndBaseUri

                    if (($Parent -is [ConfluencePS.Page]) -and ($Parent.ID)) {
                        $ParentID = $Parent.ID
                    }

                    $versionNumber = ++$originalPage.Version.Number
                    $titleValue = if ($Title) { $Title } else { $originalPage.Title }
                    $bodyValue = if ($PSBoundParameters.Keys -contains "Body") { $Body } else { $originalPage.Body }
                    $parentIdV2 = $ParentID
                }
            }

            $v2Content = [Ordered]@{
                id      = [String]$pageIdV2
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
            if ($parentIdV2) {
                $v2Content['parentId'] = [String]$parentIdV2
            }

            $v2Parameters = Copy-CommonParameter -InputObject $PSBoundParameters
            $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource PageUpdate -PageId $pageIdV2
            $v2Parameters['Method'] = 'Put'
            $v2Parameters['Body'] = $v2Content | ConvertTo-Json

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($v2Content | Out-String)"
            if ($PSCmdlet.ShouldProcess("Page $titleValue")) {
                Invoke-Method @v2Parameters | ConvertTo-PageV2 -BaseUri $BaseUri
            }
            return
        }

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Method'] = 'Put'
        $iwParameters['OutputType'] = [ConfluencePS.Page]

        $Content = [PSObject]@{
            type      = "page"
            title     = ""
            body      = [PSObject]@{
                storage = [PSObject]@{
                    value          = ""
                    representation = 'storage'
                }
            }
            version   = [PSObject]@{
                number = 0
            }
            ancestors = @()
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
                # if ($InputObject.Ancestors) {
                # $Content["ancestors"] += @( $InputObject.Ancestors | Foreach-Object { @{ id = $_.ID } } )
                # }
            }
            "byParameters" {
                $iwParameters["Uri"] = $resourceApi -f $PageID
                $originalPage = Get-Page -PageID $PageID @authAndApiUri

                if (($Parent -is [ConfluencePS.Page]) -and ($Parent.ID)) {
                    $ParentID = $Parent.ID
                }

                $Content.version.number = ++$originalPage.Version.Number
                if ($Title) { $Content.title = $Title }
                else { $Content.title = $originalPage.Title }
                # $Body might be empty
                if ($PSBoundParameters.Keys -contains "Body") {
                    $Content.body.storage.value = $Body
                }
                else {
                    $Content.body.storage.value = $originalPage.Body
                }
                # Ancestors is undocumented! May break in the future
                # http://stackoverflow.com/questions/23523705/how-to-create-new-page-in-confluence-using-their-rest-api
                if ($ParentID) {
                    $Content.ancestors = @( @{ id = $ParentID } )
                }
            }
        }

        $iwParameters["Body"] = $Content | ConvertTo-Json

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Content | Out-String)"
        If ($PSCmdlet.ShouldProcess("Page $($Content.title)")) {
            Invoke-Method @iwParameters
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
