function Resolve-Route {
    <#
    .SYNOPSIS
    Resolves the deployment- and version-aware base route for a Confluence resource operation.

    .DESCRIPTION
    Confluence Cloud resource operations that have a supported v2 replacement resolve under
    `/wiki/api/v2`. Confluence Cloud operations with a documented v2 parity gap, and every
    Data Center operation, resolve under `/rest/api` (with the Cloud `/wiki` prefix retained
    where applicable). Routes are built from fixed templates and validated identifiers only;
    no caller-supplied host or path fragment is ever accepted.
    #>
    [CmdletBinding()]
    [OutputType([Uri])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $BaseUri,

        [Parameter(Mandatory)]
        [ValidateSet(
            'SpaceCollection', 'SpaceById', 'SpaceCreate', 'SpaceDelete',
            'PageCollection', 'PageById', 'PageSearch', 'PageCreate', 'PageUpdate', 'PageDelete',
            'ChildPage', 'DescendantPage', 'PageAncestor', 'PageVersionCollection', 'PageVersionById',
            'BlogPostCollection', 'BlogPostById', 'BlogPostCreate', 'BlogPostUpdate', 'BlogPostDelete',
            'AttachmentCollection', 'AttachmentUpload', 'AttachmentUpdate', 'AttachmentDownload', 'AttachmentDelete',
            'LabelCollection', 'LabelAdd', 'LabelRemove',
            'FooterCommentCollection', 'FooterCommentById', 'FooterCommentCreate', 'FooterCommentUpdate', 'FooterCommentDelete',
            'InlineCommentCollection', 'InlineCommentById', 'InlineCommentCreate', 'InlineCommentUpdate', 'InlineCommentDelete',
            'DatabaseCollection', 'DatabaseById',
            'FolderCollection', 'FolderById',
            'WhiteboardCollection', 'WhiteboardById',
            'InlineTaskCollection', 'InlineTaskById', 'InlineTaskUpdate',
            'SpacePropertyCollection', 'SpacePropertyById',
            'SpacePermissionCollection',
            'SpaceRoleAssignmentCollection', 'SpaceRoleAssignmentUpdate',
            'StorageFormatConversion', 'ServerInformation'
        )]
        [String]
        $Resource,

        [Parameter()]
        [ValidateSet('', 'Cloud', 'DataCenter', 'Server')]
        [String]
        $DeploymentType,

        [Parameter()]
        [UInt64]
        $PageId,

        [Parameter()]
        [UInt64]
        $SpaceId,

        [Parameter()]
        [String]
        $SpaceKey,

        [Parameter()]
        [UInt64]
        $AttachmentId,

        [Parameter()]
        [UInt64]
        $CommentId,

        [Parameter()]
        [UInt32]
        $VersionNumber,

        [Parameter()]
        [UInt64]
        $DatabaseId,

        [Parameter()]
        [UInt64]
        $FolderId,

        [Parameter()]
        [UInt64]
        $WhiteboardId,

        [Parameter()]
        [UInt64]
        $TaskId,

        [Parameter()]
        [UInt64]
        $PropertyId
    )

    process {
        $deployment = if ([String]::IsNullOrWhiteSpace($DeploymentType)) { 'DataCenter' } else { $DeploymentType }
        if ($deployment -eq 'Server') {
            $deployment = 'DataCenter'
        }

        $parsedBaseUri = $null
        if (-not [Uri]::TryCreate($BaseUri, [UriKind]::Absolute, [ref]$parsedBaseUri)) {
            throw "BaseUri '$BaseUri' is not an absolute URI."
        }

        if ($deployment -eq 'Cloud' -and $parsedBaseUri.Scheme -ne 'https') {
            throw "Confluence Cloud routes require an HTTPS BaseUri."
        }

        # Cloud v2 has a supported replacement for these operations; everything else (Cloud
        # parity gaps and all Data Center traffic) resolves to the v1 `/rest/api` route.
        $v2CapableResources = @(
            'SpaceCollection', 'SpaceById', 'SpaceCreate',
            'PageCollection', 'PageById', 'PageCreate', 'PageUpdate', 'PageDelete',
            'ChildPage', 'DescendantPage', 'PageAncestor', 'PageVersionCollection', 'PageVersionById',
            'AttachmentCollection', 'AttachmentDelete',
            'LabelCollection',
            'BlogPostCollection', 'BlogPostById', 'BlogPostCreate', 'BlogPostUpdate', 'BlogPostDelete',
            'FooterCommentCollection', 'FooterCommentById', 'FooterCommentCreate', 'FooterCommentUpdate', 'FooterCommentDelete',
            'InlineCommentCollection', 'InlineCommentById', 'InlineCommentCreate', 'InlineCommentUpdate', 'InlineCommentDelete',
            'DatabaseCollection', 'DatabaseById',
            'FolderCollection', 'FolderById',
            'WhiteboardCollection', 'WhiteboardById',
            'InlineTaskCollection', 'InlineTaskById', 'InlineTaskUpdate',
            'SpacePropertyCollection', 'SpacePropertyById',
            'SpacePermissionCollection',
            'SpaceRoleAssignmentCollection', 'SpaceRoleAssignmentUpdate'
        )
        $useV2 = ($deployment -eq 'Cloud') -and ($Resource -in $v2CapableResources)

        $root = ConvertTo-RouteRoot -BaseUri $parsedBaseUri -DeploymentType $deployment
        $apiBase = if ($useV2) { "$root/api/v2" } else { "$root/rest/api" }

        $path = switch ($Resource) {
            'SpaceCollection' { if ($useV2) { '/spaces' } else { '/space' } }
            'SpaceById' {
                if ($useV2) {
                    Assert-RouteId -Name SpaceId -Value $SpaceId
                    "/spaces/$SpaceId"
                }
                else {
                    Assert-RouteKey -Name SpaceKey -Value $SpaceKey
                    "/space/$SpaceKey"
                }
            }
            'SpaceCreate' { if ($useV2) { '/spaces' } else { '/space' } }
            'SpaceDelete' {
                Assert-RouteKey -Name SpaceKey -Value $SpaceKey
                "/space/$SpaceKey"
            }
            'PageCollection' { if ($useV2) { '/pages' } else { '/content' } }
            'PageById' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId" } else { "/content/$PageId" }
            }
            'PageSearch' { '/content/search' }
            'PageCreate' { if ($useV2) { '/pages' } else { '/content' } }
            'PageUpdate' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId" } else { "/content/$PageId" }
            }
            'PageDelete' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId" } else { "/content/$PageId" }
            }
            'ChildPage' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId/direct-children" } else { "/content/$PageId/child/page" }
            }
            'DescendantPage' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId/descendants" } else { "/content/$PageId/descendant/page" }
            }
            'PageAncestor' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId/ancestors" } else { "/content/$PageId" }
            }
            'PageVersionCollection' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId/versions" } else { "/content/$PageId/version" }
            }
            'PageVersionById' {
                Assert-RouteId -Name PageId -Value $PageId
                Assert-RouteId -Name VersionNumber -Value $VersionNumber
                if ($useV2) { "/pages/$PageId/versions/$VersionNumber" } else { "/content/$PageId" }
            }
            'AttachmentCollection' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId/attachments" } else { "/content/$PageId/child/attachment" }
            }
            'AttachmentUpload' {
                Assert-RouteId -Name PageId -Value $PageId
                "/content/$PageId/child/attachment"
            }
            'AttachmentUpdate' {
                Assert-RouteId -Name PageId -Value $PageId
                Assert-RouteId -Name AttachmentId -Value $AttachmentId
                "/content/$PageId/child/attachment/$AttachmentId/data"
            }
            'AttachmentDownload' {
                Assert-RouteId -Name PageId -Value $PageId
                Assert-RouteId -Name AttachmentId -Value $AttachmentId
                "/content/$PageId/child/attachment/$AttachmentId/download"
            }
            'AttachmentDelete' {
                Assert-RouteId -Name AttachmentId -Value $AttachmentId
                if ($useV2) { "/attachments/$AttachmentId" } else { "/content/$AttachmentId" }
            }
            'LabelCollection' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId/labels" } else { "/content/$PageId/label" }
            }
            'LabelAdd' {
                Assert-RouteId -Name PageId -Value $PageId
                "/content/$PageId/label"
            }
            'LabelRemove' {
                Assert-RouteId -Name PageId -Value $PageId
                "/content/$PageId/label"
            }
            'BlogPostCollection' { if ($useV2) { '/blogposts' } else { '/content' } }
            'BlogPostById' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/blogposts/$PageId" } else { "/content/$PageId" }
            }
            'BlogPostCreate' { if ($useV2) { '/blogposts' } else { '/content' } }
            'BlogPostUpdate' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/blogposts/$PageId" } else { "/content/$PageId" }
            }
            'BlogPostDelete' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/blogposts/$PageId" } else { "/content/$PageId" }
            }
            'FooterCommentCollection' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId/footer-comments" } else { "/content/$PageId/child/comment" }
            }
            'FooterCommentById' {
                Assert-RouteId -Name CommentId -Value $CommentId
                if ($useV2) { "/footer-comments/$CommentId" } else { "/content/$CommentId" }
            }
            'FooterCommentCreate' { if ($useV2) { '/footer-comments' } else { '/content' } }
            'FooterCommentUpdate' {
                Assert-RouteId -Name CommentId -Value $CommentId
                if ($useV2) { "/footer-comments/$CommentId" } else { "/content/$CommentId" }
            }
            'FooterCommentDelete' {
                Assert-RouteId -Name CommentId -Value $CommentId
                if ($useV2) { "/footer-comments/$CommentId" } else { "/content/$CommentId" }
            }
            'InlineCommentCollection' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId/inline-comments" } else { "/content/$PageId/child/comment" }
            }
            'InlineCommentById' {
                Assert-RouteId -Name CommentId -Value $CommentId
                if ($useV2) { "/inline-comments/$CommentId" } else { "/content/$CommentId" }
            }
            'InlineCommentCreate' {
                if (-not $useV2) {
                    throw "InlineCommentCreate has no Confluence v1 or Data Center equivalent; supply an HTTPS -BaseUri with -DeploymentType Cloud."
                }
                '/inline-comments'
            }
            'InlineCommentUpdate' {
                Assert-RouteId -Name CommentId -Value $CommentId
                if ($useV2) { "/inline-comments/$CommentId" } else { "/content/$CommentId" }
            }
            'InlineCommentDelete' {
                Assert-RouteId -Name CommentId -Value $CommentId
                if ($useV2) { "/inline-comments/$CommentId" } else { "/content/$CommentId" }
            }
            'DatabaseCollection' {
                if (-not $useV2) {
                    throw "DatabaseCollection has no Confluence v1 or Data Center equivalent; supply an HTTPS -BaseUri with -DeploymentType Cloud."
                }
                '/databases'
            }
            'DatabaseById' {
                if (-not $useV2) {
                    throw "DatabaseById has no Confluence v1 or Data Center equivalent; supply an HTTPS -BaseUri with -DeploymentType Cloud."
                }
                Assert-RouteId -Name DatabaseId -Value $DatabaseId
                "/databases/$DatabaseId"
            }
            'FolderCollection' {
                if (-not $useV2) {
                    throw "FolderCollection has no Confluence v1 or Data Center equivalent; supply an HTTPS -BaseUri with -DeploymentType Cloud."
                }
                '/folders'
            }
            'FolderById' {
                if (-not $useV2) {
                    throw "FolderById has no Confluence v1 or Data Center equivalent; supply an HTTPS -BaseUri with -DeploymentType Cloud."
                }
                Assert-RouteId -Name FolderId -Value $FolderId
                "/folders/$FolderId"
            }
            'WhiteboardCollection' {
                if (-not $useV2) {
                    throw "WhiteboardCollection has no Confluence v1 or Data Center equivalent; supply an HTTPS -BaseUri with -DeploymentType Cloud."
                }
                '/whiteboards'
            }
            'WhiteboardById' {
                if (-not $useV2) {
                    throw "WhiteboardById has no Confluence v1 or Data Center equivalent; supply an HTTPS -BaseUri with -DeploymentType Cloud."
                }
                Assert-RouteId -Name WhiteboardId -Value $WhiteboardId
                "/whiteboards/$WhiteboardId"
            }
            'InlineTaskCollection' {
                if (-not $useV2) {
                    throw "InlineTaskCollection has no Confluence v1 or Data Center equivalent; supply an HTTPS -BaseUri with -DeploymentType Cloud."
                }
                '/tasks'
            }
            'InlineTaskById' {
                if (-not $useV2) {
                    throw "InlineTaskById has no Confluence v1 or Data Center equivalent; supply an HTTPS -BaseUri with -DeploymentType Cloud."
                }
                Assert-RouteId -Name TaskId -Value $TaskId
                "/tasks/$TaskId"
            }
            'InlineTaskUpdate' {
                if (-not $useV2) {
                    throw "InlineTaskUpdate has no Confluence v1 or Data Center equivalent; supply an HTTPS -BaseUri with -DeploymentType Cloud."
                }
                Assert-RouteId -Name TaskId -Value $TaskId
                "/tasks/$TaskId"
            }
            'SpacePropertyCollection' {
                if (-not $useV2) {
                    throw "SpacePropertyCollection has no Confluence v1 or Data Center equivalent; supply an HTTPS -BaseUri with -DeploymentType Cloud."
                }
                Assert-RouteId -Name SpaceId -Value $SpaceId
                "/spaces/$SpaceId/properties"
            }
            'SpacePropertyById' {
                if (-not $useV2) {
                    throw "SpacePropertyById has no Confluence v1 or Data Center equivalent; supply an HTTPS -BaseUri with -DeploymentType Cloud."
                }
                Assert-RouteId -Name SpaceId -Value $SpaceId
                Assert-RouteId -Name PropertyId -Value $PropertyId
                "/spaces/$SpaceId/properties/$PropertyId"
            }
            'SpacePermissionCollection' {
                if (-not $useV2) {
                    throw "SpacePermissionCollection has no Confluence v1 or Data Center equivalent; supply an HTTPS -BaseUri with -DeploymentType Cloud."
                }
                Assert-RouteId -Name SpaceId -Value $SpaceId
                "/spaces/$SpaceId/permissions"
            }
            'SpaceRoleAssignmentCollection' {
                if (-not $useV2) {
                    throw "SpaceRoleAssignmentCollection has no Confluence v1 or Data Center equivalent; supply an HTTPS -BaseUri with -DeploymentType Cloud."
                }
                Assert-RouteId -Name SpaceId -Value $SpaceId
                "/spaces/$SpaceId/role-assignments"
            }
            'SpaceRoleAssignmentUpdate' {
                if (-not $useV2) {
                    throw "SpaceRoleAssignmentUpdate has no Confluence v1 or Data Center equivalent; supply an HTTPS -BaseUri with -DeploymentType Cloud."
                }
                Assert-RouteId -Name SpaceId -Value $SpaceId
                "/spaces/$SpaceId/role-assignments"
            }
            'StorageFormatConversion' { '/contentbody/convert/storage' }
            'ServerInformation' { '/settings/systemInfo' }
        }

        return [Uri]"$apiBase$path"
    }
}
