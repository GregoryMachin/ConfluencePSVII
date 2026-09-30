#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePSVII {
    Describe "ConvertTo-OAuthResource" -Tag 'Unit' {
        It "converts a raw accessible-resources item to a typed OAuthResource" {
            $raw = ConvertFrom-Json '{
                "id": "11223344-A1B2-3B33-C444-DEF123456789",
                "name": "Example Site",
                "url": "https://example.atlassian.net",
                "scopes": ["read:confluence-content.all", "write:confluence-content"],
                "avatarUrl": "https://example.atlassian.net/avatar.png"
            }'

            $result = $raw | ConvertTo-OAuthResource

            $result | Should -BeOfType [ConfluencePSVII.OAuthResource]
            $result.CloudId | Should -Be '11223344-a1b2-3b33-c444-def123456789'
            $result.Name | Should -Be 'Example Site'
            $result.Url.AbsoluteUri | Should -Be 'https://example.atlassian.net/'
            $result.Scopes | Should -Be @('read:confluence-content.all', 'write:confluence-content')
            $result.AvatarUrl.AbsoluteUri | Should -Be 'https://example.atlassian.net/avatar.png'
        }

        It "leaves AvatarUrl `$null when avatarUrl is missing" {
            $raw = ConvertFrom-Json '{
                "id": "11223344-a1b2-3b33-c444-def123456789",
                "name": "Example Site",
                "url": "https://example.atlassian.net",
                "scopes": []
            }'

            (@($raw) | ConvertTo-OAuthResource).AvatarUrl | Should -BeNullOrEmpty
        }

        It "throws for an invalid id" {
            $raw = ConvertFrom-Json '{
                "id": "not-a-guid",
                "name": "Example Site",
                "url": "https://example.atlassian.net",
                "scopes": []
            }'

            { $raw | ConvertTo-OAuthResource } | Should -Throw
        }
    }
}
