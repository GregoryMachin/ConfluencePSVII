function New-Page {
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true,
        DefaultParameterSetName = 'byParameters'
    )]
    [OutputType([ConfluencePSVII.Page])]
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
        [ConfluencePSVII.Page]$InputObject,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ParameterSetName = 'byParameters'
        )]
        [Alias('Name')]
        [String]$Title,

        [Parameter(ParameterSetName = 'byParameters')]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [UInt64]$ParentID,

        [Parameter(ParameterSetName = 'byParameters')]
        [ConfluencePSVII.Page]$Parent,

        [Parameter(ParameterSetName = 'byParameters')]
        [String]$SpaceKey,

        [Parameter(ParameterSetName = 'byParameters')]
        [ConfluencePSVII.Space]$Space,

        [Parameter(ParameterSetName = 'byParameters')]
        [String]$Body,

        [Parameter(ParameterSetName = 'byParameters')]
        [Switch]$Convert
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $resourceApi = "$ApiUri/content"

        #this is the splat hashtable that passes the auth and uri to calls but not Invoke-Method, i.e. Get-Page
        $authAndApiUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter "ApiUri"
        # Same, but also forwards -BaseUri/-DeploymentType, for calls (Get-Page, Get-Space)
        # that support Cloud v2 routing; ConvertTo-StorageFormat does not accept them, so it
        # keeps using $authAndApiUri above.
        $authApiAndBaseUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter @('ApiUri', 'BaseUri', 'DeploymentType')

        # Cloud v2 opt-in (Task 48): -BaseUri + -DeploymentType Cloud route page creation to
        # POST /pages. v2 identifies the target space only by numeric ID, so a -SpaceKey (or
        # -Space/-InputObject.Space with only a Key) is resolved through Get-ConfluenceSpace.
        $useCloudV2 = ($DeploymentType -eq 'Cloud') -and $BaseUri
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($useCloudV2) {
            $spaceId = $null
            $parentIdV2 = $null

            switch ($PsCmdlet.ParameterSetName) {
                "byObject" {
                    $titleValue = $InputObject.Title
                    $bodyValue = $InputObject.Body
                    if ($InputObject.Space.Id) {
                        $spaceId = $InputObject.Space.Id
                    }
                    elseif ($InputObject.Space.Key) {
                        $spaceId = (Get-Space -SpaceKey $InputObject.Space.Key @authApiAndBaseUri).Id
                    }
                    if ($InputObject.Ancestors) {
                        $parentIdV2 = ($InputObject.Ancestors | Select-Object -Last 1).ID
                    }
                }
                "byParameters" {
                    if (($Parent -is [ConfluencePSVII.Page]) -and ($Parent.ID)) {
                        $ParentID = $Parent.ID
                    }

                    if (($Space -is [ConfluencePSVII.Space]) -and ($Space.Id)) {
                        $spaceId = $Space.Id
                    }
                    elseif (($Space -is [ConfluencePSVII.Space]) -and ($Space.Key)) {
                        $spaceId = (Get-Space -SpaceKey $Space.Key @authApiAndBaseUri).Id
                    }
                    elseif ($SpaceKey) {
                        $spaceId = (Get-Space -SpaceKey $SpaceKey @authApiAndBaseUri).Id
                    }
                    elseif ($ParentID) {
                        Write-Verbose "[$($MyInvocation.MyCommand.Name)] SpaceKey not specified. Retrieving from Get-ConfluencePage -PageID $ParentID"
                        $spaceId = (Get-Page -PageID $ParentID @authApiAndBaseUri).Space.Id
                    }

                    if ($Convert) {
                        Write-Verbose '[$($MyInvocation.MyCommand.Name)] -Convert flag active; converting content to Confluence storage format'
                        $Body = ConvertTo-StorageFormat -Content $Body @authAndApiUri
                    }

                    $titleValue = $Title
                    $bodyValue = $Body
                    $parentIdV2 = $ParentID
                }
            }

            $v2Content = [Ordered]@{
                spaceId = [String]$spaceId
                status  = 'current'
                title   = $titleValue
                body    = @{
                    representation = 'storage'
                    value          = $bodyValue
                }
            }
            if ($parentIdV2) {
                $v2Content['parentId'] = [String]$parentIdV2
            }

            $v2Parameters = Copy-CommonParameter -InputObject $PSBoundParameters
            $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource PageCreate
            $v2Parameters['Method'] = 'Post'
            $v2Parameters['Body'] = $v2Content | ConvertTo-Json

            Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($v2Content | Out-String)"
            if ($PSCmdlet.ShouldProcess("Space $spaceId")) {
                Invoke-Method @v2Parameters | ConvertTo-PageV2 -BaseUri $BaseUri
            }
            return
        }

        $iwParameters = Copy-CommonParameter -InputObject $PSBoundParameters
        $iwParameters['Uri'] = $resourceApi
        $iwParameters['Method'] = 'Post'
        $iwParameters['OutputType'] = [ConfluencePSVII.Page]

        $Content = [PSObject]@{
            type      = "page"
            space     = [PSObject]@{ key = "" }
            title     = ""
            body      = [PSObject]@{
                storage = [PSObject]@{
                    representation = 'storage'
                }
            }
            ancestors = @()
        }

        switch ($PsCmdlet.ParameterSetName) {
            "byObject" {
                $Content.title = $InputObject.Title
                $Content.space.key = $InputObject.Space.Key
                $Content.body.storage.value = $InputObject.Body
                if ($InputObject.Ancestors) {
                    $Content.ancestors += @( $InputObject.Ancestors | ForEach-Object { @{ id = $_.ID } } )
                }
            }
            "byParameters" {
                if (($Parent -is [ConfluencePSVII.Page]) -and ($Parent.ID)) {
                    $ParentID = $Parent.ID
                }
                if (($Space -is [ConfluencePSVII.Space]) -and ($Space.Key)) {
                    $SpaceKey = $Space.Key
                }

                if (($ParentID) -and !($SpaceKey)) {
                    Write-Verbose "[$($MyInvocation.MyCommand.Name)] SpaceKey not specified. Retrieving from Get-ConfluencePage -PageID $ParentID"
                    $SpaceKey = (Get-Page -PageID $ParentID @authAndApiUri).Space.Key
                }

                # If -Convert is flagged, call ConvertTo-ConfluenceStorageFormat against the -Body
                if ($Convert) {
                    Write-Verbose '[$($MyInvocation.MyCommand.Name)] -Convert flag active; converting content to Confluence storage format'
                    $Body = ConvertTo-StorageFormat -Content $Body @authAndApiUri
                }

                $Content.title = $Title
                $Content.space = @{ key = $SpaceKey }
                $Content.body.storage.value = $Body
                if ($ParentID) {
                    $Content.ancestors = @( @{ id = $ParentID } )
                }
            }
        }

        $iwParameters["Body"] = $Content | ConvertTo-Json

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($Content | Out-String)"
        If ($PSCmdlet.ShouldProcess("Space $($Content.space.key)")) {
            Invoke-Method @iwParameters
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
