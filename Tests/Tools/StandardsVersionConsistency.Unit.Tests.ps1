#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

Describe 'AtlassianPSVII.Standards version consistency' -Tag Unit {
    BeforeAll {
        function Get-RepositoryRoot {
            if (
                $env:BHProjectPath -and
                (Test-Path -LiteralPath (Join-Path -Path $env:BHProjectPath -ChildPath 'ConfluencePSVII.build.ps1'))
            ) {
                return (Resolve-Path -LiteralPath $env:BHProjectPath).ProviderPath
            }

            $candidate = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath
            while ($candidate -and ($candidate -ne [System.IO.Path]::GetPathRoot($candidate))) {
                if (
                    (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'ConfluencePSVII.build.ps1')) -and
                    (Test-Path -LiteralPath (Join-Path -Path $candidate -ChildPath 'Tools/build.requirements.psd1'))
                ) {
                    return $candidate
                }

                $candidate = Split-Path -Path $candidate -Parent
            }

            throw "Could not resolve repository root from '$PSScriptRoot'."
        }
    }

    It 'keeps workflow setup action pins aligned with build.requirements' {
        $projectRoot = Get-RepositoryRoot

        $buildRequirementsPath = Join-Path -Path $projectRoot -ChildPath 'Tools/build.requirements.psd1'
        # Parse the array-style requirements file: Import-PowerShellDataFile returns only its first entry.
        $buildRequirements = @([System.Management.Automation.Language.Parser]::ParseFile($buildRequirementsPath, [ref]$null, [ref]$null).EndBlock.Statements[0].PipelineElements[0].Expression.SafeGetValue())
        $standardsRequirement = $buildRequirements |
            Where-Object { $_.ModuleName -eq 'AtlassianPSVII.Standards' } |
            Select-Object -First 1

        if (-not $standardsRequirement -or -not $standardsRequirement.RequiredVersion) {
            $tokens = $null
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($buildRequirementsPath, [ref]$tokens, [ref]$parseErrors)
            if ($parseErrors -and $parseErrors.Count -gt 0) {
                throw "Unable to parse build requirements file '$buildRequirementsPath': $($parseErrors[0].Message)"
            }

            $statement = $ast.EndBlock.Statements[0]
            if (
                $statement -isnot [System.Management.Automation.Language.PipelineAst] -or
                $statement.PipelineElements[0] -isnot [System.Management.Automation.Language.CommandExpressionAst]
            ) {
                throw "Build requirements file '$buildRequirementsPath' does not contain a supported data expression."
            }

            $buildRequirements = @($statement.PipelineElements[0].Expression.SafeGetValue())
            $standardsRequirement = $buildRequirements |
                Where-Object { $_.ModuleName -eq 'AtlassianPSVII.Standards' } |
                Select-Object -First 1
        }

        $standardsVersion = [string] $standardsRequirement.RequiredVersion
        $standardsVersion | Should -Not -BeNullOrEmpty

        $workflowPaths = Get-ChildItem -Path (Join-Path -Path $projectRoot -ChildPath '.github/workflows') -File -Filter '*.yml' |
            Select-Object -ExpandProperty FullName

        $workflowActionMatches = foreach ($workflowPath in $workflowPaths) {
            $workflowContent = Get-Content -LiteralPath $workflowPath -Raw
            [regex]::Matches(
                $workflowContent,
                "GregoryMachin/AtlassianPSVII\.Standards/\.github/actions/setup-powershell@(?<ref>[^\s#]+)(?:\s+#\s+v(?<version>[0-9]+\.[0-9]+\.[0-9]+))?"
            ) | ForEach-Object {
                [PSCustomObject]@{
                    WorkflowPath = $workflowPath
                    Ref          = $_.Groups['ref'].Value
                    Version      = $_.Groups['version'].Value
                }
            }
        }

        @($workflowActionMatches).Count | Should -BeGreaterThan 0

        @($workflowActionMatches | Where-Object { $_.Ref -notmatch '^[0-9a-f]{40}$' }).Count | Should -Be 0
        @($workflowActionMatches | Where-Object { [string]::IsNullOrWhiteSpace($_.Version) }).Count | Should -Be 0

        @($workflowActionMatches | Select-Object -ExpandProperty Ref -Unique).Count | Should -Be 1

        $matchedVersions = @(
            $workflowActionMatches |
                Select-Object -ExpandProperty Version -Unique
        )
        $matchedVersions.Count | Should -Be 1
        $matchedVersions[0] | Should -Be $standardsVersion
    }

    It 'reads AtlassianPSVII.Standards version from build.requirements in tool scripts' {
        $projectRoot = Get-RepositoryRoot

        $setupScriptContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'Tools/setup.ps1') -Raw
        $updateScriptContent = Get-Content -LiteralPath (Join-Path -Path $projectRoot -ChildPath 'Tools/update.dependencies.ps1') -Raw

        $setupScriptContent | Should -Match '\$buildRequirements\s*=\s*@\(\[System\.Management\.Automation\.Language\.Parser\]::ParseFile\('
        $setupScriptContent | Should -Not -Match '\$standardsVersion\s*=\s*'''
        $setupScriptContent | Should -Match '-RequiredVersion\s+\$standardsVersion'

        $updateScriptContent | Should -Match '\$buildRequirements\s*=\s*@\(\[System\.Management\.Automation\.Language\.Parser\]::ParseFile\('
        $updateScriptContent | Should -Not -Match '\$standardsVersion\s*=\s*'''
        $updateScriptContent | Should -Match '-RequiredVersion\s+\$standardsVersion'
        $updateScriptContent | Should -Match '\$PSCmdlet\.ShouldProcess\('
        $updateScriptContent | Should -Match 'AtlassianPSVII\.Standards\\Update-AtlassianPSVIIDependencyReference'
    }
}
