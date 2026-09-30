#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
    $script:projectRoot = Resolve-ProjectRoot
    Import-Module $moduleToTest -Force -ErrorAction Stop
}

Describe 'ConfluencePSVII API contract inventory' -Tag Unit, Documentation {
    BeforeDiscovery {
        $script:inventoryPath = Join-Path $projectRoot 'docs/api-contract-inventory.md'
        $script:inventoryLines = Get-Content -LiteralPath $inventoryPath
        $script:exportedCommands = @(
            (Get-Module 'ConfluencePSVII').ExportedFunctions.Keys | Sort-Object
        )

        $script:inventoryRows = @(
            foreach ($line in $inventoryLines) {
                if ($line -notmatch '^\| \[(?<Command>[^\]]+)\]\((?<Source>[^)]+)\) \|') {
                    continue
                }

                $cells = @($line.Trim('|').Split('|') | ForEach-Object { $_.Trim() })
                [pscustomobject]@{
                    Command = $Matches.Command
                    Source  = $Matches.Source
                    Cells   = $cells
                }
            }
        )

        $sourceFiles = @(
            Get-ChildItem -Path (Join-Path $projectRoot 'ConfluencePSVII/Public') -Filter '*.ps1' -File
            Get-ChildItem -Path (Join-Path $projectRoot 'ConfluencePSVII/Private') -Filter '*.ps1' -File
        )

        $script:expectedSourceByCommand = @{}
        foreach ($sourceFile in $sourceFiles) {
            $nameParts = $sourceFile.BaseName -split '-', 2
            $exportedName = '{0}-Confluence{1}' -f $nameParts[0], $nameParts[1]
            $relativeSource = '../ConfluencePSVII/{0}/{1}' -f $sourceFile.Directory.Name, $sourceFile.Name
            $script:expectedSourceByCommand[$exportedName] = $relativeSource
        }

        $script:localReferences = @(
            $inventoryLines |
                Select-String -AllMatches -Pattern '\((?<Target>\.\./[^)#]+)(?:#[^)]+)?\)' |
                ForEach-Object { $_.Matches } |
                ForEach-Object { $_.Groups['Target'].Value } |
                Sort-Object -Unique
        )

        $script:inventoryCase = @(
            [pscustomobject]@{
                InventoryPath    = $inventoryPath
                InventoryRows    = $inventoryRows
                ExportedCommands = $exportedCommands
                ExpectedCommands = @($expectedSourceByCommand.Keys | Sort-Object)
            }
        )

        $script:commandCases = @(
            foreach ($commandName in ($expectedSourceByCommand.Keys | Sort-Object)) {
                [pscustomobject]@{
                    Command        = $commandName
                    Rows           = @($inventoryRows | Where-Object Command -eq $commandName)
                    ExpectedSource = $expectedSourceByCommand[$commandName]
                    HasSource      = $expectedSourceByCommand.ContainsKey($commandName)
                }
            }
        )

        $script:referenceCases = @(
            foreach ($reference in $localReferences) {
                [pscustomobject]@{
                    Reference = $reference
                    Resolved  = Join-Path (Split-Path $inventoryPath -Parent) $reference
                }
            }
        )
    }

    Context 'Inventory document' -ForEach $script:inventoryCase {
        BeforeAll {
            $script:documentCase = $_
        }

        It 'exists' {
            $documentCase.InventoryPath | Should -Exist
        }

        It 'contains exactly one row for every source-surface function' {
            @($documentCase.InventoryRows.Command | Sort-Object) |
                Should -Be $documentCase.ExpectedCommands
            @($documentCase.InventoryRows.Command | Select-Object -Unique).Count |
                Should -Be $documentCase.InventoryRows.Count
        }

        It 'contains every function exported by the module artifact under test' {
            $missingExports = @(
                $documentCase.ExportedCommands |
                    Where-Object { $_ -notin $documentCase.InventoryRows.Command }
            )

            $missingExports | Should -BeNullOrEmpty
        }
    }

    Context 'Exported command <Command>' -ForEach $script:commandCases {
        BeforeAll {
            $script:commandCase = $_
        }

        It 'maps to its implementation file' {
            $commandCase.Rows.Count | Should -Be 1
            $commandCase.HasSource | Should -BeTrue
            $commandCase.Rows[0].Source | Should -Be $commandCase.ExpectedSource
        }
    }

    Context 'Inventory row <Command>' -ForEach $script:inventoryRows {
        BeforeAll {
            $script:inventoryRow = $_
        }

        It 'records all twelve required contract columns' {
            $inventoryRow.Cells.Count | Should -Be 12
            @($inventoryRow.Cells | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count |
                Should -Be 0
        }
    }

    Context 'Referenced local file <Reference>' -ForEach $script:referenceCases {
        BeforeAll {
            $script:referenceCase = $_
        }

        It 'exists' {
            $referenceCase.Resolved | Should -Exist
        }
    }
}
