function Set-Info {
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseShouldProcessForStateChangingFunctions', '')]
    param (
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Example = https://brianbunke.atlassian.net/wiki (/wiki for Cloud instances)'
        )]
        [Alias('Uri')]
        [Object]$BaseURi,

        [PSCredential]$Credential,

        [String]$PersonalAccessToken,

        [SecureString]$OAuthAccessToken,

        [String]$CloudId,

        [String]$OAuthClientId,

        [SecureString]$OAuthClientSecret,

        [String]$SiteName,

        [Uri]$SiteUrl,

        [UInt32]$PageSize,

        [Switch]$PromptCredentials
    )

    BEGIN {

        function Add-ConfluenceDefaultParameter {
            param(
                [Parameter(Mandatory = $true)]
                [String]$Command,

                [Parameter(Mandatory = $true)]
                [String]$Parameter,

                [Parameter(Mandatory = $true)]
                $Value
            )

            PROCESS {
                Write-Verbose "[$($MyInvocation.MyCommand.Name)] Setting [$command : $parameter] = $value"

                # Needs to set caller, module, and global scope for nested functions and module commands:
                # http://stackoverflow.com/questions/30427110/set-psdefaultparametersvalues-for-use-within-module-scope
                $PSDefaultParameterValues["${command}:${parameter}"] = $Value
                $script:PSDefaultParameterValues["${command}:${parameter}"] = $Value
                $global:PSDefaultParameterValues["${command}:${parameter}"] = $Value
            }
        }

        $moduleCommands = Get-Command -Module ConfluencePS

        if ($PromptCredentials) {
            $Credential = (Get-Credential)
        }
    }

    PROCESS {
        $usingClientCredentials = $PSBoundParameters.ContainsKey('OAuthClientId') -or $PSBoundParameters.ContainsKey('OAuthClientSecret')

        if (($PSBoundParameters.ContainsKey('SiteName') -or $PSBoundParameters.ContainsKey('SiteUrl')) -and -not $usingClientCredentials) {
            throw [System.ArgumentException]::new('-SiteName and -SiteUrl are only valid together with -OAuthClientId/-OAuthClientSecret.')
        }

        if ($usingClientCredentials) {
            if (-not ($PSBoundParameters.ContainsKey('OAuthClientId') -and $PSBoundParameters.ContainsKey('OAuthClientSecret'))) {
                throw [System.ArgumentException]::new('-OAuthClientId and -OAuthClientSecret must be supplied together.')
            }
            if ($PSBoundParameters.ContainsKey('OAuthAccessToken')) {
                throw [System.ArgumentException]::new('Specify either -OAuthAccessToken or -OAuthClientId/-OAuthClientSecret, not both.')
            }

            $tokenResult = Request-OAuthClientCredentialsToken -ClientId $OAuthClientId -ClientSecret $OAuthClientSecret

            # A non-interactive service account may be authorized for more than one site;
            # -CloudId/-SiteName/-SiteUrl narrow that down, the same selector Get-ConfluenceOAuthResource
            # itself accepts. With no selector, more than one reachable site is an error rather than
            # an arbitrary silent pick.
            $selectorParameters = @{}
            foreach ($selectorName in 'CloudId', 'SiteName', 'SiteUrl') {
                if ($PSBoundParameters.ContainsKey($selectorName)) {
                    $selectorParameters[$selectorName] = $PSBoundParameters[$selectorName]
                }
            }

            $matchedResource = @(Get-OAuthResource -OAuthAccessToken $tokenResult.AccessToken @selectorParameters)
            if ($matchedResource.Count -eq 0) {
                throw [System.Management.Automation.ItemNotFoundException]::new('The OAuth client-credentials token cannot reach any Confluence Cloud site.')
            }
            if ($matchedResource.Count -gt 1) {
                throw [System.InvalidOperationException]::new('The OAuth client-credentials token can reach multiple sites; disambiguate with -CloudId, -SiteName, or -SiteUrl.')
            }

            $OAuthAccessToken = $tokenResult.AccessToken
            $CloudId = $matchedResource[0].CloudId
        }

        if ($usingClientCredentials -or $PSBoundParameters.ContainsKey('OAuthAccessToken')) {
            if ($BaseURi) {
                throw [System.ArgumentException]::new('Specify either -BaseUri or -OAuthAccessToken/-OAuthClientId, not both.')
            }
            if (-not $CloudId) {
                throw [System.ArgumentException]::new('-CloudId is required when -OAuthAccessToken is supplied.', 'CloudId')
            }

            # Reuses the same Resolve-ConfiguredInfo path a pipelined AtlassianPS.Configuration
            # entry already takes: an OAuth Cloud session is just Cloud + OAuth metadata on the
            # gateway URI, so no separate resolution logic is needed here.
            $oauthGatewayUri = Resolve-OAuthBaseUri -CloudId $CloudId
            $BaseURi = [PSCustomObject]@{
                Uri                = $oauthGatewayUri.AbsoluteUri
                Type               = 'Confluence'
                Product            = 'Confluence'
                DeploymentType     = 'Cloud'
                AuthenticationType = 'OAuth'
                CloudId            = $CloudId
            }

            $tokenPlain = [System.Net.NetworkCredential]::new('', $OAuthAccessToken).Password
            if ([String]::IsNullOrWhiteSpace($tokenPlain)) {
                throw [System.ArgumentException]::new('OAuthAccessToken must not be empty.', 'OAuthAccessToken')
            }
            $PersonalAccessToken = $tokenPlain
        }

        $configuredInfo = $null
        if ($BaseURi) {
            $configuredInfo = Resolve-ConfiguredInfo -BaseUri $BaseURi
            $script:ConfluenceRequestContext = @{
                BaseUri            = $configuredInfo.BaseUri
                ApiUri             = $configuredInfo.ApiUri
                Product            = $configuredInfo.Metadata.Product
                DeploymentType     = $configuredInfo.Metadata.DeploymentType
                AuthenticationType = $configuredInfo.Metadata.AuthenticationType
                CloudId            = $configuredInfo.Metadata.CloudId
            }
        }

        foreach ($command in $moduleCommands) {
            if ($command.Name -in @('Set-ConfluenceInfo', 'Set-Info')) {
                # Skip Set-ConfluenceInfo itself: Get-Command -Module returns both its
                # prefixed and unprefixed CommandInfo, and its own -BaseURi parameter
                # name-matches the new -BaseUri default case-insensitively, which would
                # otherwise make a later parameterless call silently reuse the previous
                # base URI.
                continue
            }

            $parameter = "ApiUri"
            if ($configuredInfo -and ($command.Parameters.Keys -contains $parameter)) {
                Add-ConfluenceDefaultParameter -Command $command -Parameter $parameter -Value $configuredInfo.ApiUri.AbsoluteUri.TrimEnd('/')
            }

            $parameter = "BaseUri"
            if ($configuredInfo -and ($command.Parameters.Keys -contains $parameter)) {
                Add-ConfluenceDefaultParameter -Command $command -Parameter $parameter -Value $configuredInfo.BaseUri
            }

            $parameter = "DeploymentType"
            if ($configuredInfo -and $configuredInfo.Metadata.DeploymentType -and ($command.Parameters.Keys -contains $parameter)) {
                Add-ConfluenceDefaultParameter -Command $command -Parameter $parameter -Value $configuredInfo.Metadata.DeploymentType
            }

            $parameter = "Credential"
            if ($Credential -and ($command.Parameters.Keys -contains $parameter)) {
                Add-ConfluenceDefaultParameter -Command $command -Parameter $parameter -Value $Credential
            }

            $parameter = "PersonalAccessToken"
            if ($PersonalAccessToken -and ($command.Parameters.Keys -contains $parameter)) {
                Add-ConfluenceDefaultParameter -Command $command -Parameter $parameter -Value $PersonalAccessToken
            }

            $parameter = "PageSize"
            if ($PageSize -and ($command.Parameters.Keys -contains $parameter)) {
                Add-ConfluenceDefaultParameter -Command $command -Parameter $parameter -Value $PageSize
            }
        }
    }
}
