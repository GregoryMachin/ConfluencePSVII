function New-InlineComment {
    # Cloud v2 only: Confluence's v1/Data Center content API has no operation for creating an
    # inline (text-anchored) comment, only generic page comments. See
    # docs/api-contract-inventory.md for the parity gap.
    [CmdletBinding(
        ConfirmImpact = 'Low',
        SupportsShouldProcess = $true
    )]
    [OutputType([ConfluencePSVII.Comment])]
    param (
        [Parameter( Mandatory = $true )]
        [Uri]$ApiUri,

        [Parameter( Mandatory = $true )]
        [Uri]$BaseUri,

        [Parameter( Mandatory = $false )]
        [PSCredential]$Credential,

        [Parameter( Mandatory = $false )]
        [String]
        $PersonalAccessToken,

        [Parameter( Mandatory = $false )]
        [ValidateNotNull()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $Certificate,

        [Parameter( Mandatory = $true, ValueFromPipelineByPropertyName = $true )]
        [ValidateRange(1, [UInt64]::MaxValue)]
        [UInt64]$PageID,

        [Parameter( Mandatory = $true )]
        [ValidateNotNullOrEmpty()]
        [String]$TextSelection,

        [Parameter()]
        [ValidateRange(1, [UInt32]::MaxValue)]
        [UInt32]$TextSelectionMatchCount = 1,

        [Parameter()]
        [UInt32]$TextSelectionMatchIndex = 0,

        [Parameter()]
        [UInt64]$ParentCommentID,

        [Parameter( Mandatory = $true )]
        [String]$Body,

        [Parameter()]
        [Switch]$Convert
    )

    BEGIN {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $authAndApiUri = Copy-CommonParameter -InputObject $PSBoundParameters -AdditionalParameter "ApiUri"
    }

    PROCESS {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        if ($Convert) {
            Write-Verbose '[$($MyInvocation.MyCommand.Name)] -Convert flag active; converting content to Confluence storage format'
            $Body = ConvertTo-StorageFormat -Content $Body @authAndApiUri
        }

        $v2Content = [Ordered]@{
            pageId                  = [String]$PageID
            body                    = @{
                representation = 'storage'
                value          = $Body
            }
            inlineCommentProperties = @{
                textSelection           = $TextSelection
                textSelectionMatchCount = $TextSelectionMatchCount
                textSelectionMatchIndex = $TextSelectionMatchIndex
            }
        }
        if ($ParentCommentID) {
            $v2Content['parentCommentId'] = [String]$ParentCommentID
        }

        $v2Parameters = Copy-CommonParameter -InputObject $PSBoundParameters
        # Resolve-Route throws for InlineCommentCreate unless -DeploymentType Cloud and an
        # HTTPS -BaseUri are supplied -- this operation has no v1/Data Center equivalent.
        $v2Parameters['Uri'] = Resolve-Route -BaseUri $BaseUri -DeploymentType Cloud -Resource InlineCommentCreate
        $v2Parameters['Method'] = 'Post'
        $v2Parameters['Body'] = $v2Content | ConvertTo-Json -Depth 5

        Write-Debug "[$($MyInvocation.MyCommand.Name)] Content to be sent: $($v2Content | Out-String)"
        if ($PSCmdlet.ShouldProcess("Page $PageID")) {
            Invoke-Method @v2Parameters | ConvertTo-CommentV2 -Type inline -BaseUri $BaseUri
        }
    }

    END {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function ended"
    }
}
