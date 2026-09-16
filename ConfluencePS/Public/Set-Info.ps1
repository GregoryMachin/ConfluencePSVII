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
