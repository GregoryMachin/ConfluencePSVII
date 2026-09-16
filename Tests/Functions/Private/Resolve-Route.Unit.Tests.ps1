#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment -CallerPath $PSScriptRoot
    Import-Module $script:moduleToTest -Force -ErrorAction Stop
}

InModuleScope ConfluencePS {
    Describe "Resolve-Route" -Tag 'Unit' {
        BeforeAll {
            $script:cloudBase = 'https://example.atlassian.net'
            $script:dcBase = 'https://confluence.example.com/confluence'
        }

        Context "Cloud v2-capable resources" -ForEach @(
            @{ Resource = 'SpaceCollection'; Params = @{}; Expected = '/wiki/api/v2/spaces' }
            @{ Resource = 'SpaceById'; Params = @{ SpaceId = 42 }; Expected = '/wiki/api/v2/spaces/42' }
            @{ Resource = 'SpaceCreate'; Params = @{}; Expected = '/wiki/api/v2/spaces' }
            @{ Resource = 'PageCollection'; Params = @{}; Expected = '/wiki/api/v2/pages' }
            @{ Resource = 'PageById'; Params = @{ PageId = 100 }; Expected = '/wiki/api/v2/pages/100' }
            @{ Resource = 'PageCreate'; Params = @{}; Expected = '/wiki/api/v2/pages' }
            @{ Resource = 'PageUpdate'; Params = @{ PageId = 100 }; Expected = '/wiki/api/v2/pages/100' }
            @{ Resource = 'PageDelete'; Params = @{ PageId = 100 }; Expected = '/wiki/api/v2/pages/100' }
            @{ Resource = 'ChildPage'; Params = @{ PageId = 100 }; Expected = '/wiki/api/v2/pages/100/direct-children' }
            @{ Resource = 'DescendantPage'; Params = @{ PageId = 100 }; Expected = '/wiki/api/v2/pages/100/descendants' }
            @{ Resource = 'AttachmentCollection'; Params = @{ PageId = 100 }; Expected = '/wiki/api/v2/pages/100/attachments' }
            @{ Resource = 'AttachmentDelete'; Params = @{ AttachmentId = 55 }; Expected = '/wiki/api/v2/attachments/55' }
            @{ Resource = 'LabelCollection'; Params = @{ PageId = 100 }; Expected = '/wiki/api/v2/pages/100/labels' }
            @{ Resource = 'BlogPostCollection'; Params = @{}; Expected = '/wiki/api/v2/blogposts' }
            @{ Resource = 'BlogPostById'; Params = @{ PageId = 100 }; Expected = '/wiki/api/v2/blogposts/100' }
            @{ Resource = 'BlogPostCreate'; Params = @{}; Expected = '/wiki/api/v2/blogposts' }
            @{ Resource = 'BlogPostUpdate'; Params = @{ PageId = 100 }; Expected = '/wiki/api/v2/blogposts/100' }
            @{ Resource = 'BlogPostDelete'; Params = @{ PageId = 100 }; Expected = '/wiki/api/v2/blogposts/100' }
            @{ Resource = 'FooterCommentCollection'; Params = @{ PageId = 100 }; Expected = '/wiki/api/v2/pages/100/footer-comments' }
            @{ Resource = 'FooterCommentById'; Params = @{ CommentId = 200 }; Expected = '/wiki/api/v2/footer-comments/200' }
            @{ Resource = 'FooterCommentCreate'; Params = @{}; Expected = '/wiki/api/v2/footer-comments' }
            @{ Resource = 'FooterCommentUpdate'; Params = @{ CommentId = 200 }; Expected = '/wiki/api/v2/footer-comments/200' }
            @{ Resource = 'FooterCommentDelete'; Params = @{ CommentId = 200 }; Expected = '/wiki/api/v2/footer-comments/200' }
            @{ Resource = 'InlineCommentCollection'; Params = @{ PageId = 100 }; Expected = '/wiki/api/v2/pages/100/inline-comments' }
            @{ Resource = 'InlineCommentById'; Params = @{ CommentId = 200 }; Expected = '/wiki/api/v2/inline-comments/200' }
            @{ Resource = 'InlineCommentCreate'; Params = @{}; Expected = '/wiki/api/v2/inline-comments' }
            @{ Resource = 'InlineCommentUpdate'; Params = @{ CommentId = 200 }; Expected = '/wiki/api/v2/inline-comments/200' }
            @{ Resource = 'InlineCommentDelete'; Params = @{ CommentId = 200 }; Expected = '/wiki/api/v2/inline-comments/200' }
        ) {
            It "resolves <Resource> to the v2 route on Cloud" {
                $uri = Resolve-Route -BaseUri $cloudBase -DeploymentType Cloud -Resource $Resource @Params

                $uri.AbsoluteUri | Should -BeExactly "$cloudBase$Expected"
            }
        }

        Context "Cloud parity-gap resources retain v1" -ForEach @(
            @{ Resource = 'PageSearch'; Params = @{}; Expected = '/wiki/rest/api/content/search' }
            @{ Resource = 'AttachmentUpload'; Params = @{ PageId = 100 }; Expected = '/wiki/rest/api/content/100/child/attachment' }
            @{ Resource = 'AttachmentUpdate'; Params = @{ PageId = 100; AttachmentId = 55 }; Expected = '/wiki/rest/api/content/100/child/attachment/55/data' }
            @{ Resource = 'AttachmentDownload'; Params = @{ PageId = 100; AttachmentId = 55 }; Expected = '/wiki/rest/api/content/100/child/attachment/55/download' }
            @{ Resource = 'LabelAdd'; Params = @{ PageId = 100 }; Expected = '/wiki/rest/api/content/100/label' }
            @{ Resource = 'LabelRemove'; Params = @{ PageId = 100 }; Expected = '/wiki/rest/api/content/100/label' }
            @{ Resource = 'StorageFormatConversion'; Params = @{}; Expected = '/wiki/rest/api/contentbody/convert/storage' }
            @{ Resource = 'ServerInformation'; Params = @{}; Expected = '/wiki/rest/api/settings/systemInfo' }
            @{ Resource = 'SpaceDelete'; Params = @{ SpaceKey = 'TEST' }; Expected = '/wiki/rest/api/space/TEST' }
        ) {
            It "resolves <Resource> to the v1 route on Cloud" {
                $uri = Resolve-Route -BaseUri $cloudBase -DeploymentType Cloud -Resource $Resource @Params

                $uri.AbsoluteUri | Should -BeExactly "$cloudBase$Expected"
            }
        }

        Context "Data Center always uses v1, without a /wiki prefix" -ForEach @(
            @{ Resource = 'SpaceCollection'; Params = @{}; Expected = '/rest/api/space' }
            @{ Resource = 'SpaceById'; Params = @{ SpaceKey = 'TEST' }; Expected = '/rest/api/space/TEST' }
            @{ Resource = 'SpaceDelete'; Params = @{ SpaceKey = 'TEST' }; Expected = '/rest/api/space/TEST' }
            @{ Resource = 'PageCollection'; Params = @{}; Expected = '/rest/api/content' }
            @{ Resource = 'PageById'; Params = @{ PageId = 100 }; Expected = '/rest/api/content/100' }
            @{ Resource = 'PageSearch'; Params = @{}; Expected = '/rest/api/content/search' }
            @{ Resource = 'ChildPage'; Params = @{ PageId = 100 }; Expected = '/rest/api/content/100/child/page' }
            @{ Resource = 'DescendantPage'; Params = @{ PageId = 100 }; Expected = '/rest/api/content/100/descendant/page' }
            @{ Resource = 'AttachmentCollection'; Params = @{ PageId = 100 }; Expected = '/rest/api/content/100/child/attachment' }
            @{ Resource = 'AttachmentDelete'; Params = @{ AttachmentId = 55 }; Expected = '/rest/api/content/55' }
            @{ Resource = 'LabelCollection'; Params = @{ PageId = 100 }; Expected = '/rest/api/content/100/label' }
            @{ Resource = 'StorageFormatConversion'; Params = @{}; Expected = '/rest/api/contentbody/convert/storage' }
            @{ Resource = 'ServerInformation'; Params = @{}; Expected = '/rest/api/settings/systemInfo' }
            @{ Resource = 'BlogPostCollection'; Params = @{}; Expected = '/rest/api/content' }
            @{ Resource = 'BlogPostById'; Params = @{ PageId = 100 }; Expected = '/rest/api/content/100' }
            @{ Resource = 'BlogPostCreate'; Params = @{}; Expected = '/rest/api/content' }
            @{ Resource = 'BlogPostUpdate'; Params = @{ PageId = 100 }; Expected = '/rest/api/content/100' }
            @{ Resource = 'BlogPostDelete'; Params = @{ PageId = 100 }; Expected = '/rest/api/content/100' }
            @{ Resource = 'FooterCommentCollection'; Params = @{ PageId = 100 }; Expected = '/rest/api/content/100/child/comment' }
            @{ Resource = 'FooterCommentById'; Params = @{ CommentId = 200 }; Expected = '/rest/api/content/200' }
            @{ Resource = 'FooterCommentCreate'; Params = @{}; Expected = '/rest/api/content' }
            @{ Resource = 'FooterCommentUpdate'; Params = @{ CommentId = 200 }; Expected = '/rest/api/content/200' }
            @{ Resource = 'FooterCommentDelete'; Params = @{ CommentId = 200 }; Expected = '/rest/api/content/200' }
            @{ Resource = 'InlineCommentCollection'; Params = @{ PageId = 100 }; Expected = '/rest/api/content/100/child/comment' }
            @{ Resource = 'InlineCommentById'; Params = @{ CommentId = 200 }; Expected = '/rest/api/content/200' }
            @{ Resource = 'InlineCommentUpdate'; Params = @{ CommentId = 200 }; Expected = '/rest/api/content/200' }
            @{ Resource = 'InlineCommentDelete'; Params = @{ CommentId = 200 }; Expected = '/rest/api/content/200' }
        ) {
            It "resolves <Resource> to the Data Center v1 route" {
                $uri = Resolve-Route -BaseUri $dcBase -DeploymentType DataCenter -Resource $Resource @Params

                $uri.AbsoluteUri | Should -BeExactly "$dcBase$Expected"
            }

            It "resolves <Resource> the same way for an empty DeploymentType (legacy default)" {
                $uri = Resolve-Route -BaseUri $dcBase -DeploymentType '' -Resource $Resource @Params

                $uri.AbsoluteUri | Should -BeExactly "$dcBase$Expected"
            }

            It "treats DeploymentType Server the same as DataCenter for <Resource>" {
                $uri = Resolve-Route -BaseUri $dcBase -DeploymentType Server -Resource $Resource @Params

                $uri.AbsoluteUri | Should -BeExactly "$dcBase$Expected"
            }
        }

        Context "context path preservation" {
            It "keeps a Data Center context path intact" {
                $uri = Resolve-Route -BaseUri 'https://dc.example.com/confluence' -DeploymentType DataCenter -Resource ServerInformation

                $uri.AbsoluteUri | Should -BeExactly 'https://dc.example.com/confluence/rest/api/settings/systemInfo'
            }

            It "does not duplicate an already-present /wiki suffix on Cloud" {
                $uri = Resolve-Route -BaseUri 'https://example.atlassian.net/wiki' -DeploymentType Cloud -Resource ServerInformation

                $uri.AbsoluteUri | Should -BeExactly 'https://example.atlassian.net/wiki/rest/api/settings/systemInfo'
            }

            It "trims a trailing slash from BaseUri before building the route" {
                $uri = Resolve-Route -BaseUri 'https://dc.example.com/confluence/' -DeploymentType DataCenter -Resource ServerInformation

                $uri.AbsoluteUri | Should -BeExactly 'https://dc.example.com/confluence/rest/api/settings/systemInfo'
            }
        }

        Context "identifier validation" {
            It "throws for a zero PageId" {
                { Resolve-Route -BaseUri $cloudBase -DeploymentType Cloud -Resource PageById -PageId 0 } |
                    Should -Throw "*PageId*"
            }

            It "throws for a missing AttachmentId on an attachment route" {
                { Resolve-Route -BaseUri $cloudBase -DeploymentType Cloud -Resource AttachmentDelete } |
                    Should -Throw "*AttachmentId*"
            }

            It "throws for an empty SpaceKey on a v1-only space route" {
                { Resolve-Route -BaseUri $dcBase -DeploymentType DataCenter -Resource SpaceDelete } |
                    Should -Throw "*SpaceKey*"
            }

            It "throws for a SpaceKey containing a path separator" {
                { Resolve-Route -BaseUri $dcBase -DeploymentType DataCenter -Resource SpaceDelete -SpaceKey 'TEST/../ADMIN' } |
                    Should -Throw
            }

            It "throws for a missing CommentId on a footer comment by-id route" {
                { Resolve-Route -BaseUri $cloudBase -DeploymentType Cloud -Resource FooterCommentById } |
                    Should -Throw "*CommentId*"
            }

            It "throws for InlineCommentCreate on Data Center, since it has no v1 equivalent" {
                { Resolve-Route -BaseUri $dcBase -DeploymentType DataCenter -Resource InlineCommentCreate } |
                    Should -Throw "*Cloud*"
            }

            It "throws for InlineCommentCreate on Cloud without an HTTPS BaseUri" {
                { Resolve-Route -BaseUri 'http://example.atlassian.net' -DeploymentType Cloud -Resource InlineCommentCreate } |
                    Should -Throw
            }

            It "resolves InlineCommentCreate on Cloud with an HTTPS BaseUri" {
                $uri = Resolve-Route -BaseUri $cloudBase -DeploymentType Cloud -Resource InlineCommentCreate

                $uri.AbsoluteUri | Should -BeExactly "$cloudBase/wiki/api/v2/inline-comments"
            }

            It "throws for an invalid Resource value" {
                { Resolve-Route -BaseUri $cloudBase -DeploymentType Cloud -Resource 'NotARealResource' } |
                    Should -Throw
            }
        }

        Context "unsupported and untrusted input" {
            It "throws for a relative BaseUri" {
                { Resolve-Route -BaseUri '/wiki' -DeploymentType Cloud -Resource ServerInformation } |
                    Should -Throw "*absolute*"
            }

            It "throws for a non-HTTPS Cloud BaseUri" {
                { Resolve-Route -BaseUri 'http://example.atlassian.net' -DeploymentType Cloud -Resource ServerInformation } |
                    Should -Throw "*HTTPS*"
            }

            It "allows a non-HTTPS Data Center BaseUri" {
                { Resolve-Route -BaseUri 'http://dc.example.com/confluence' -DeploymentType DataCenter -Resource ServerInformation } |
                    Should -Not -Throw
            }

            It "ignores a query string on an absolute-link-shaped BaseUri rather than forwarding it" {
                $uri = Resolve-Route -BaseUri 'https://example.atlassian.net?cursor=opaque-token' -DeploymentType Cloud -Resource ServerInformation

                $uri.AbsoluteUri | Should -BeExactly 'https://example.atlassian.net/wiki/rest/api/settings/systemInfo'
            }

            It "ignores a fragment on an absolute-link-shaped BaseUri rather than forwarding it" {
                $uri = Resolve-Route -BaseUri 'https://example.atlassian.net#section' -DeploymentType Cloud -Resource ServerInformation

                $uri.AbsoluteUri | Should -BeExactly 'https://example.atlassian.net/wiki/rest/api/settings/systemInfo'
            }

            It "does not accept a second URI to merge or follow, keeping pagination-link handling out of this function's scope" {
                (Get-Command Resolve-Route).Parameters.Keys | Should -Not -Contain 'NextLink'
            }
        }
    }
}
