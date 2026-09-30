function ConvertTo-BlogPost {
    <#
    .SYNOPSIS
    Extracted the conversion to private function in order to have a single place to
    select the properties to use when casting to custom object type
    #>
    [CmdletBinding()]
    [OutputType( [ConfluencePSVII.BlogPost] )]
    param (
        # object to convert
        [Parameter( Position = 0, ValueFromPipeline = $true )]
        $InputObject
    )

    process {
        foreach ($object in $InputObject) {
            Write-Verbose "[$($MyInvocation.MyCommand.Name)] Converting Object to BlogPost"
            [ConfluencePSVII.BlogPost](ConvertTo-Hashtable -InputObject ($object | Select-Object `
                        id,
                    status,
                    title,
                    @{Name = "space"; Expression = {
                            if ($_.space) {
                                ConvertTo-Space $_.space
                            }
                            else { $null }
                        }
                    },
                    @{Name = "version"; Expression = {
                            if ($_.version) {
                                ConvertTo-Version $_.version
                            }
                            else { $null }
                        }
                    },
                    @{Name = "body"; Expression = { $_.body.storage.value } },
                    @{Name = "URL"; Expression = {
                            $base = $_._links.base
                            if (!($base)) { $base = $_._links.self -replace '\/rest.*', '' }
                            if ($_._links.webui) {
                                "{0}{1}" -f $base, $_._links.webui
                            }
                            else { $null }
                        }
                    },
                    @{Name = "ShortURL"; Expression = {
                            $base = $_._links.base
                            if (!($base)) { $base = $_._links.self -replace '\/rest.*', '' }
                            if ($_._links.tinyui) {
                                "{0}{1}" -f $base, $_._links.tinyui
                            }
                            else { $null }
                        }
                    }
                ))
        }
    }
}
