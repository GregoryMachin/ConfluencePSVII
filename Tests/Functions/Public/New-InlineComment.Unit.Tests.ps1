#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "New-InlineComment" -Tag 'Unit' {
        BeforeEach {
            Mock Invoke-Method -ModuleName ConfluencePS {
                param([Uri]$Uri, [string]$Body)
                $script:lastUri = $Uri.AbsoluteUri
                $script:lastBody = ConvertFrom-Json -InputObject $Body -ErrorAction Stop
                ConvertFrom-Json '{"id": "327680", "status": "current", "pageId": "196608", "body": {"storage": {"value": "<p>Careful here</p>"}}}'
            }
        }

        It "routes to the v2 inline-comments route and sends the text-selection anchor" {
            $result = New-InlineComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -PageID 196608 -TextSelection "the exact phrase" -Body "<p>Careful here</p>" -Confirm:$false

            $script:lastUri | Should -Be "https://example.atlassian.net/wiki/api/v2/inline-comments"
            $script:lastBody.pageId | Should -Be '196608'
            $script:lastBody.body.value | Should -Be '<p>Careful here</p>'
            $script:lastBody.inlineCommentProperties.textSelection | Should -Be 'the exact phrase'
            $script:lastBody.inlineCommentProperties.textSelectionMatchCount | Should -Be 1
            $script:lastBody.inlineCommentProperties.textSelectionMatchIndex | Should -Be 0
            $result | Should -BeOfType [ConfluencePS.Comment]
            $result.Type | Should -Be 'inline'
        }

        It "forwards a non-default match count and index" {
            $null = New-InlineComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -PageID 196608 -TextSelection "ambiguous phrase" -TextSelectionMatchCount 3 -TextSelectionMatchIndex 1 -Body "<p>Hi</p>" -Confirm:$false

            $script:lastBody.inlineCommentProperties.textSelectionMatchCount | Should -Be 3
            $script:lastBody.inlineCommentProperties.textSelectionMatchIndex | Should -Be 1
        }

        It "sends parentCommentId for a reply" {
            $null = New-InlineComment -ApiUri "https://example.atlassian.net/wiki/rest/api" -BaseUri "https://example.atlassian.net" -PageID 196608 -TextSelection "the exact phrase" -ParentCommentID 327679 -Body "<p>Reply</p>" -Confirm:$false

            $script:lastBody.parentCommentId | Should -Be '327679'
        }

        It "throws when -BaseUri is not an HTTPS URI, since inline comments have no v1/Data Center equivalent" {
            { New-InlineComment -ApiUri "http://dc.example.com/rest/api" -BaseUri "http://dc.example.com" -PageID 196608 -TextSelection "text" -Body "<p>Hi</p>" -Confirm:$false } | Should -Throw
        }
    }
}
